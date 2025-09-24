import Foundation
import Combine

/// Provides derived data for the receipts tab including grouping and search.
final class ReceiptListViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet { regroup() }
    }
    @Published fileprivate(set) var groupedReceipts: [ReceiptCategory: [Receipt]] = [:]

    private var cancellable: AnyCancellable?
    private var receipts: [Receipt] = [] {
        didSet { regroup() }
    }

    func bind(to store: ReceiptStore) {
        cancellable = store.$receipts
            .sink { [weak self] in self?.receipts = $0 }
    }

    fileprivate func updateGroup(with receipts: [Receipt]) {
        self.receipts = receipts
    }

    private func regroup() {
        groupedReceipts = Self.group(receipts: receipts, search: searchText)
    }

    static func group(receipts: [Receipt], search: String) -> [ReceiptCategory: [Receipt]] {
        let filtered: [Receipt]
        if search.isEmpty {
            filtered = receipts
        } else {
            let lower = search.lowercased()
            filtered = receipts.filter { receipt in
                receipt.title.lowercased().contains(lower)
                    || receipt.merchantName.lowercased().contains(lower)
                    || receipt.keywords.contains { $0.lowercased().contains(lower) }
            }
        }

        return Dictionary(grouping: filtered, by: \Receipt.category)
            .mapValues { $0.sorted { $0.purchaseDate > $1.purchaseDate } }
    }
}
