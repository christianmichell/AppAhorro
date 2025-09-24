import Foundation
import Combine

/// Generates analytics summaries and publishes updates whenever receipts change.
final class ReceiptAnalyticsService: ObservableObject {
    @Published private(set) var monthlySummary: AnalyticsSummary?
    @Published private(set) var recentSpending: [AnalyticsSummary.DailySpend] = []

    private var cancellable: AnyCancellable?

    func configure(with store: ReceiptStore) {
        cancellable = store.$receipts
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { receipts in
                Self.buildSummary(for: receipts)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in
                self?.monthlySummary = summary
                self?.recentSpending = summary?.dailySpending ?? []
            }
    }

    private static func buildSummary(for receipts: [Receipt]) -> AnalyticsSummary? {
        guard let month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) else {
            return nil
        }

        let monthReceipts = receipts.filter { Calendar.current.isDate($0.purchaseDate, equalTo: Date(), toGranularity: .month) }
        guard !monthReceipts.isEmpty else { return nil }

        let total = monthReceipts.reduce(Decimal(0)) { $0 + $1.amount }
        let tax = monthReceipts.reduce(Decimal(0)) { $0 + ($1.taxAmount ?? 0) }

        let breakdown = Dictionary(grouping: monthReceipts, by: { $0.category })
            .map { category, items in
                AnalyticsSummary.CategoryBreakdown(
                    id: category,
                    total: items.reduce(Decimal(0)) { $0 + $1.amount },
                    transactionCount: items.count
                )
            }
            .sorted { $0.total > $1.total }

        let groupedByDay = Dictionary(grouping: monthReceipts) { receipt in
            Calendar.current.startOfDay(for: receipt.purchaseDate)
        }
        let daily = groupedByDay.map { date, items in
            AnalyticsSummary.DailySpend(date: date, total: items.reduce(Decimal(0)) { $0 + $1.amount })
        }
        .sorted { $0.date < $1.date }

        var keywordFrequency: [String: Int] = [:]
        monthReceipts.forEach { receipt in
            receipt.keywords.forEach { keyword in
                keywordFrequency[keyword, default: 0] += 1
            }
        }

        return AnalyticsSummary(
            month: month,
            totalSpent: total,
            taxPaid: tax,
            categoryBreakdown: breakdown,
            dailySpending: daily,
            keywords: keywordFrequency
        )
    }
}
