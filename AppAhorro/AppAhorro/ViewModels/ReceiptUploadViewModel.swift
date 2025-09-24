import Foundation
import UIKit

/// Drives the add-receipt flow including manual form fields and AI enrichment status.
final class ReceiptUploadViewModel: ObservableObject {
    enum UploadState {
        case idle
        case processing
        case success(Receipt)
        case failure(Error)
    }

    @Published var description: String = ""
    @Published var captureDate: Date = Date()
    @Published var locationDescription: String = ""
    @Published private(set) var state: UploadState = .idle

    private weak var store: ReceiptStore?

    func bind(to store: ReceiptStore) {
        self.store = store
    }

    func reset() {
        description = ""
        captureDate = Date()
        locationDescription = ""
        state = .idle
    }

    func submit(image: UIImage, filename: String = "captura.jpg") {
        guard let data = image.jpegData(compressionQuality: 0.9), let store else { return }
        state = .processing
        store.add(
            attachmentData: data,
            filename: filename,
            mimeType: "image/jpeg",
            manualDescription: description,
            captureDate: captureDate,
            locationDescription: locationDescription.isEmpty ? nil : locationDescription
        ) { [weak self] result in
            switch result {
            case let .success(receipt):
                self?.state = .success(receipt)
            case let .failure(error):
                self?.state = .failure(error)
            }
        }
    }
}
