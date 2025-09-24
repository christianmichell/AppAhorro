import XCTest
@testable import AppAhorro

final class AppAhorroTests: XCTestCase {
    func testReceiptGroupingByCategory() throws {
        let receipt = Receipt(
            title: "Consulta médica",
            merchantName: "Clínica Mayo",
            purchaseDate: Date(),
            amount: 25000,
            category: .health,
            keywords: ["salud"],
            attachment: .init(relativePath: "test", thumbnailRelativePath: nil, mimeType: "image/jpeg"),
            metadata: [:]
        )
        let grouped = ReceiptListViewModel.group(receipts: [receipt], search: "")
        XCTAssertEqual(grouped[.health]?.count, 1)
    }
}
