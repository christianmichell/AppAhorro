import Foundation
import NaturalLanguage

/// Resolves natural language questions over the stored receipts using a combination of keyword matching and heuristics.
final class ReceiptQueryEngine: ObservableObject {
    @Published private(set) var lastQuery: ReceiptQuery?
    @Published private(set) var lastResults: [Receipt] = []

    private var receiptsProvider: () -> [Receipt] = { [] }

    func configure(with store: ReceiptStore) {
        receiptsProvider = { store.receipts }
    }

    func performQuery(_ prompt: String) {
        let query = ReceiptQuery(prompt: prompt, filters: filters(for: prompt))
        lastQuery = query
        lastResults = search(with: query)
    }

    private func search(with query: ReceiptQuery) -> [Receipt] {
        let receipts = receiptsProvider()
        guard !receipts.isEmpty else { return [] }

        let tokens = tokenise(query.prompt)
        let filtered = receipts.filter { receipt in
            let haystack = (receipt.keywords + receipt.tags + [receipt.title, receipt.merchantName, receipt.description ?? ""]).joined(separator: " ").lowercased()
            let matchesTokens = tokens.allSatisfy { haystack.contains($0) }

            let filterMatch = query.filters.allSatisfy { filter in
                switch filter.kind {
                case .keyword:
                    return receipt.keywords.contains { $0.localizedCaseInsensitiveContains(filter.value) }
                case .category:
                    return receipt.category.rawValue == filter.value
                case .merchant:
                    return receipt.merchantName.localizedCaseInsensitiveContains(filter.value)
                case .amountRange:
                    let components = filter.value.split(separator: "-").compactMap { Decimal(string: String($0)) }
                    guard components.count == 2 else { return true }
                    return receipt.amount >= components[0] && receipt.amount <= components[1]
                case .dateRange:
                    let formatter = ISO8601DateFormatter()
                    let components = filter.value.split(separator: "|").compactMap { formatter.date(from: String($0)) }
                    guard components.count == 2 else { return true }
                    return receipt.purchaseDate >= components[0] && receipt.purchaseDate <= components[1]
                }
            }

            return matchesTokens || filterMatch
        }

        return filtered.sorted { $0.purchaseDate > $1.purchaseDate }
    }

    private func tokenise(_ text: String) -> [String] {
        let lower = text.lowercased()
        let tagger = NLTokenizer(unit: .word)
        tagger.string = lower
        var tokens: [String] = []
        tagger.enumerateTokens(in: lower.startIndex..<lower.endIndex) { range, _ in
            tokens.append(String(lower[range]))
            return true
        }
        return tokens.filter { $0.count > 2 }
    }

    private func filters(for prompt: String) -> [ReceiptQuery.Filter] {
        var filters: [ReceiptQuery.Filter] = []
        let lower = prompt.lowercased()

        for category in ReceiptCategory.allCases {
            if lower.contains(category.title.lowercased()) || lower.contains(category.rawValue) {
                filters.append(.init(kind: .category, value: category.rawValue))
            }
        }

        let months = [
            "enero", "febrero", "marzo", "abril", "mayo", "junio",
            "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
        ]
        for (index, monthName) in months.enumerated() {
            if lower.contains(monthName) {
                let calendar = Calendar.current
                var components = DateComponents()
                components.month = index + 1
                components.year = calendar.component(.year, from: Date())
                if let start = calendar.date(from: components),
                   let range = calendar.range(of: .day, in: .month, for: start),
                   let end = calendar.date(byAdding: .day, value: range.count - 1, to: start) {
                    let formatter = ISO8601DateFormatter()
                    let value = "\(formatter.string(from: start))|\(formatter.string(from: end))"
                    filters.append(.init(kind: .dateRange, value: value))
                }
            }
        }

        return filters
    }
}
