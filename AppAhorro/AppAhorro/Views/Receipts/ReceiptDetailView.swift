import SwiftUI

/// Displays complete receipt metadata and actions for sharing or deleting.
struct ReceiptDetailView: View {
    @EnvironmentObject private var store: ReceiptStore
    @Environment(\.dismiss) private var dismiss
    let receipt: Receipt

    var body: some View {
        Form {
            Section(header: Text("Información general")) {
                LabeledContent("Comercio", value: receipt.merchantName)
                LabeledContent("Título", value: receipt.title)
                if let description = receipt.description {
                    LabeledContent("Descripción", value: description)
                }
                LabeledContent("Fecha de compra", value: FormatterFactory.dayFormatter.string(from: receipt.purchaseDate))
                LabeledContent("Fecha de registro", value: FormatterFactory.dayFormatter.string(from: receipt.captureDate))
                LabeledContent("Categoría", value: receipt.category.title)
            }

            Section(header: Text("Montos")) {
                LabeledContent("Total", value: formatted(receipt.amount))
                if let taxAmount = receipt.taxAmount {
                    LabeledContent("IVA", value: formatted(taxAmount))
                }
                if let taxRate = receipt.taxRate {
                    LabeledContent("% IVA", value: "\(taxRate as NSDecimalNumber)%")
                }
            }

            Section(header: Text("Palabras clave")) {
                if receipt.keywords.isEmpty {
                    Text("No se generaron palabras clave para este documento.")
                        .foregroundStyle(.secondary)
                } else {
                    FlexibleKeywordGrid(keywords: Dictionary(uniqueKeysWithValues: receipt.keywords.map { ($0, 1) }))
                }
            }

            Section(header: Text("Acciones")) {
                Button(role: .destructive) {
                    store.delete(receipt)
                    dismiss()
                } label: {
                    Label("Eliminar boleta", systemImage: "trash")
                }
            }
        }
        .navigationTitle(receipt.title)
    }

    private func formatted(_ value: Decimal) -> String {
        FormatterFactory.currencyFormatter(for: receipt.currencyCode).string(from: value as NSDecimalNumber) ?? "--"
    }
}
