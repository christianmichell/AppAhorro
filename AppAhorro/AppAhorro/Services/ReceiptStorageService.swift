import Foundation
import UIKit

/// Persists receipts and their attachments using the user's on-device file system.
final class ReceiptStorageService {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let receiptsFilename = "receipts.json"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Reads every stored receipt from disk.
    func loadReceipts() throws -> [Receipt] {
        let url = try receiptsFileURL()
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try decoder.decode([Receipt].self, from: data)
    }

    /// Persists the provided receipts collection atomically.
    func persist(_ receipts: [Receipt]) throws {
        let url = try receiptsFileURL()
        let data = try encoder.encode(receipts)
        try data.write(to: url, options: [.atomic])
    }

    /// Stores binary data for a receipt attachment inside the documents directory.
    @discardableResult
    func storeAttachment(data: Data, originalFilename: String, mimeType: String) throws -> Receipt.Attachment {
        let sanitizedName = originalFilename.replacingOccurrences(of: " ", with: "-")
        let fileURL = try attachmentsDirectoryURL().appendingPathComponent("\(UUID().uuidString)-\(sanitizedName)")
        try data.write(to: fileURL, options: [.atomic])
        var thumbnailPath: String?
        if mimeType.starts(with: "image"), let thumbnailData = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 600, height: 600))?.jpegData(compressionQuality: 0.7) {
            let thumbURL = try thumbnailsDirectoryURL().appendingPathComponent(fileURL.lastPathComponent)
            try thumbnailData.write(to: thumbURL, options: [.atomic])
            thumbnailPath = relativePath(for: thumbURL)
        }
        return Receipt.Attachment(
            relativePath: relativePath(for: fileURL),
            thumbnailRelativePath: thumbnailPath,
            mimeType: mimeType
        )
    }

    /// Deletes the attachment data from disk.
    func deleteAttachment(_ attachment: Receipt.Attachment) throws {
        let fileURL = try resolve(relativePath: attachment.relativePath)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        if let thumbnail = attachment.thumbnailRelativePath {
            let thumbURL = try resolve(relativePath: thumbnail)
            if fileManager.fileExists(atPath: thumbURL.path) {
                try fileManager.removeItem(at: thumbURL)
            }
        }
    }

    private func receiptsFileURL() throws -> URL {
        try documentsDirectory().appendingPathComponent(receiptsFilename)
    }

    private func attachmentsDirectoryURL() throws -> URL {
        let url = try documentsDirectory().appendingPathComponent("Attachments", isDirectory: true)
        try ensureDirectoryExists(at: url)
        return url
    }

    private func thumbnailsDirectoryURL() throws -> URL {
        let url = try documentsDirectory().appendingPathComponent("Thumbnails", isDirectory: true)
        try ensureDirectoryExists(at: url)
        return url
    }

    private func documentsDirectory() throws -> URL {
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        try ensureDirectoryExists(at: url)
        return url
    }

    private func relativePath(for url: URL) -> String {
        url.path.replacingOccurrences(of: documentsDirectoryPath(), with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func resolve(relativePath: String) throws -> URL {
        let base = try documentsDirectory()
        return base.appendingPathComponent(relativePath)
    }

    private func ensureDirectoryExists(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func documentsDirectoryPath() -> String {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
    }
}
