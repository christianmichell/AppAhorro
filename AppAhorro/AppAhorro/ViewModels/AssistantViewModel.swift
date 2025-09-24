import Foundation

/// Coordinates the conversational assistant experience leveraging the query engine for retrieval.
final class AssistantViewModel: ObservableObject {
    struct Message: Identifiable, Codable {
        enum Role: String, Codable {
            case user
            case assistant
        }

        let id = UUID()
        let role: Role
        let text: String
        let timestamp: Date
    }

    @Published private(set) var conversation: [Message] = []
    private var store: ReceiptStore?
    private var queryEngine: ReceiptQueryEngine?

    func configure(with store: ReceiptStore, queryEngine: ReceiptQueryEngine) {
        self.store = store
        self.queryEngine = queryEngine
    }

    func send(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        conversation.append(Message(role: .user, text: trimmed, timestamp: Date()))
        queryEngine?.performQuery(trimmed)
        let response = buildResponse(for: trimmed)
        conversation.append(Message(role: .assistant, text: response, timestamp: Date()))
    }

    private func buildResponse(for prompt: String) -> String {
        guard let queryEngine else { return "No pude procesar tu consulta." }
        let results = queryEngine.lastResults
        guard !results.isEmpty else {
            return "No encontré boletas relevantes para tu consulta. Intenta ajustar las palabras clave o cargar nuevas boletas."
        }

        let total = results.reduce(Decimal(0)) { $0 + $1.amount }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = results.first?.currencyCode ?? "CLP"
        let totalString = formatter.string(from: total as NSDecimalNumber) ?? "-"

        let groupedByMerchant = Dictionary(grouping: results, by: { $0.merchantName })
            .map { merchant, receipts in
                "• \(merchant): \(receipts.count) documentos, total \(formatter.string(from: receipts.reduce(Decimal(0)) { $0 + $1.amount } as NSDecimalNumber) ?? "-")"
            }
            .joined(separator: "\n")

        let headline = "Resumen de \(results.count) boletas relacionadas con tu consulta:"
        return """
        \(headline)
        Total estimado: \(totalString)

        Detalle por comercio:
        \(groupedByMerchant)

        Puedes abrir la pestaña de Boletas para revisar cada documento.
        """.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
