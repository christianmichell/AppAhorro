import Foundation

/// Natural language query describing the receipts a user is interested in.
struct ReceiptQuery: Identifiable, Codable {
    let id: UUID
    let prompt: String
    let createdAt: Date
    let filters: [Filter]

    struct Filter: Codable, Hashable {
        enum Kind: String, Codable {
            case keyword
            case category
            case merchant
            case amountRange
            case dateRange
        }

        let kind: Kind
        let value: String
    }

    init(prompt: String, createdAt: Date = Date(), filters: [Filter] = []) {
        self.id = UUID()
        self.prompt = prompt
        self.createdAt = createdAt
        self.filters = filters
    }
}
