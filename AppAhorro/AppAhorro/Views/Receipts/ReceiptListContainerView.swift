import SwiftUI

/// Hosts the receipts list view with search and quick actions.
struct ReceiptListContainerView: View {
    @EnvironmentObject private var store: ReceiptStore
    @StateObject private var viewModel = ReceiptListViewModel()
    @State private var presentingCapture = false

    var body: some View {
        NavigationStack {
            ReceiptListView(groupedReceipts: viewModel.groupedReceipts, searchText: $viewModel.searchText)
                .navigationTitle("Boletas")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            presentingCapture = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
        }
        .onAppear {
            viewModel.bind(to: store)
            viewModel.updateGroup(with: store.receipts)
        }
        .sheet(isPresented: $presentingCapture) {
            ReceiptCaptureSheet()
                .environmentObject(store)
        }
    }
}

struct ReceiptListView: View {
    let groupedReceipts: [ReceiptCategory: [Receipt]]
    @Binding var searchText: String

    var body: some View {
        List {
            ForEach(ReceiptCategory.allCases, id: \ReceiptCategory.rawValue) { category in
                if let receipts = groupedReceipts[category], !receipts.isEmpty {
                    Section(header: Text(category.title)) {
                        ForEach(receipts, id: \Receipt.id) { receipt in
                            NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                                ReceiptRowView(receipt: receipt)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
    }
}

struct ReceiptRowView: View {
    let receipt: Receipt

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: receipt.category.systemImageName)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.title)
                    .font(.headline)
                Text(receipt.merchantName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(FormatterFactory.dayFormatter.string(from: receipt.purchaseDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(FormatterFactory.currencyFormatter(for: receipt.currencyCode).string(from: receipt.amount as NSDecimalNumber) ?? "-")
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}
