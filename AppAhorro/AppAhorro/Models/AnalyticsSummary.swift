import Foundation

/// Aggregated summary for dashboards and data visualisations.
struct AnalyticsSummary: Codable, Hashable {
    struct CategoryBreakdown: Codable, Hashable, Identifiable {
        let id: ReceiptCategory
        let total: Decimal
        let transactionCount: Int
    }

    struct DailySpend: Codable, Hashable, Identifiable {
        let id: UUID = UUID()
        let date: Date
        let total: Decimal
    }

    let month: Date
    let totalSpent: Decimal
    let taxPaid: Decimal
    let categoryBreakdown: [CategoryBreakdown]
    let dailySpending: [DailySpend]
    let keywords: [String: Int]
}
