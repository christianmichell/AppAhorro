import Foundation
import CoreLocation

/// Domain model representing a single receipt, invoice or proof of payment.
struct Receipt: Identifiable, Codable, Hashable {
    struct Attachment: Codable, Hashable {
        /// File URL relative to the application documents directory.
        let relativePath: String
        /// Optional thumbnail generated for quick previews.
        let thumbnailRelativePath: String?
        /// MIME type inferred from the import source.
        let mimeType: String
    }

    var id: UUID
    var title: String
    var merchantName: String
    var description: String?
    var purchaseDate: Date
    var captureDate: Date
    var amount: Decimal
    var currencyCode: String
    var taxAmount: Decimal?
    var taxRate: Decimal?
    var category: ReceiptCategory
    var keywords: [String]
    var locationDescription: String?
    var location: CLLocationCoordinate2D?
    var attachment: Attachment
    var tags: [String]
    var metadata: [String: String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        merchantName: String,
        description: String? = nil,
        purchaseDate: Date,
        captureDate: Date = Date(),
        amount: Decimal,
        currencyCode: String = "CLP",
        taxAmount: Decimal? = nil,
        taxRate: Decimal? = nil,
        category: ReceiptCategory = .other,
        keywords: [String] = [],
        locationDescription: String? = nil,
        location: CLLocationCoordinate2D? = nil,
        attachment: Attachment,
        tags: [String] = [],
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.merchantName = merchantName
        self.description = description
        self.purchaseDate = purchaseDate
        self.captureDate = captureDate
        self.amount = amount
        self.currencyCode = currencyCode
        self.taxAmount = taxAmount
        self.taxRate = taxRate
        self.category = category
        self.keywords = keywords
        self.locationDescription = locationDescription
        self.location = location
        self.attachment = attachment
        self.tags = tags
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Receipt.Attachment {
    /// Absolute file URL resolved against the application documents directory.
    func fileURL(using fileManager: FileManager = .default) -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(relativePath)
    }

    /// Returns the URL for the thumbnail if one was generated.
    func thumbnailURL(using fileManager: FileManager = .default) -> URL? {
        guard let thumbnailRelativePath else { return nil }
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(thumbnailRelativePath)
    }
}

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}
