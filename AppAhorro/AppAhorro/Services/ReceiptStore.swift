import Foundation

/// Observable store that orchestrates persistence, analytics updates and AI enrichment.
final class ReceiptStore: ObservableObject {
    @Published private(set) var receipts: [Receipt] = [] {
        didSet { persistReceipts() }
    }

    private let storageService: ReceiptStorageService
    private let analyzer: OpenAIReceiptAnalyzer

    init(
        storageService: ReceiptStorageService = ReceiptStorageService(),
        analyzer: OpenAIReceiptAnalyzer = OpenAIReceiptAnalyzer()
    ) {
        self.storageService = storageService
        self.analyzer = analyzer
        loadReceipts()
    }

    func refresh() {
        loadReceipts()
    }

    func add(
        attachmentData: Data,
        filename: String,
        mimeType: String,
        manualDescription: String?,
        captureDate: Date = Date(),
        locationDescription: String? = nil,
        completion: @escaping (Result<Receipt, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let storedAttachment = try self.storageService.storeAttachment(
                    data: attachmentData,
                    originalFilename: filename,
                    mimeType: mimeType
                )

                let analysis = try self.analyzer.analyseReceipt(
                    attachmentData: attachmentData,
                    mimeType: mimeType,
                    userDescription: manualDescription
                )

                let receipt = Receipt(
                    title: analysis.title,
                    merchantName: analysis.merchantName,
                    description: manualDescription ?? analysis.summary,
                    purchaseDate: analysis.purchaseDate ?? captureDate,
                    captureDate: captureDate,
                    amount: analysis.totalAmount,
                    currencyCode: analysis.currencyCode,
                    taxAmount: analysis.taxAmount,
                    taxRate: analysis.taxRate,
                    category: analysis.category,
                    keywords: analysis.keywords,
                    locationDescription: locationDescription ?? analysis.locationDescription,
                    location: analysis.location,
                    attachment: storedAttachment,
                    tags: analysis.tags,
                    metadata: analysis.metadata,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                DispatchQueue.main.async {
                    self.receipts.append(receipt)
                    completion(.success(receipt))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func update(_ receipt: Receipt) {
        guard let index = receipts.firstIndex(where: { $0.id == receipt.id }) else { return }
        receipts[index] = receipt
    }

    func delete(_ receipt: Receipt) {
        guard let index = receipts.firstIndex(of: receipt) else { return }
        receipts.remove(at: index)
        try? storageService.deleteAttachment(receipt.attachment)
    }

    func receipts(for category: ReceiptCategory) -> [Receipt] {
        receipts.filter { $0.category == category }
    }

    private func loadReceipts() {
        do {
            receipts = try storageService.loadReceipts()
        } catch {
            print("Error loading receipts: \(error)")
            receipts = []
        }
    }

    private func persistReceipts() {
        do {
            try storageService.persist(receipts)
        } catch {
            print("Error saving receipts: \(error)")
        }
    }
}
