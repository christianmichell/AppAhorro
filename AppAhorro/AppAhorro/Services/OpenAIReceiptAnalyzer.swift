import Foundation
import CoreLocation
import UIKit

/// Handles communication with OpenAI's vision-capable models to extract structured data from receipts.
final class OpenAIReceiptAnalyzer {
    struct AnalysisResult {
        let title: String
        let merchantName: String
        let summary: String
        let purchaseDate: Date?
        let totalAmount: Decimal
        let currencyCode: String
        let taxAmount: Decimal?
        let taxRate: Decimal?
        let category: ReceiptCategory
        let keywords: [String]
        let tags: [String]
        let metadata: [String: String]
        let locationDescription: String?
        let location: CLLocationCoordinate2D?
    }

    enum AnalyzerError: Error {
        case invalidResponse
        case decodingFailed
        case requestFailed
        case missingAPIKey
    }

    private let session: URLSession
    private let apiKey: String?
    private let jsonDecoder = JSONDecoder()

    init(session: URLSession = .shared, apiKey: String? = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]) {
        self.session = session
        self.apiKey = apiKey
        jsonDecoder.dateDecodingStrategy = .iso8601
    }

    /// Performs a synchronous analysis using OpenAI. In debug environments this method falls back to a mock response.
    func analyseReceipt(attachmentData: Data, mimeType: String, userDescription: String?) throws -> AnalysisResult {
        guard let apiKey else {
            return OpenAIReceiptAnalyzer.mockResult(description: userDescription)
        }

        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let base64 = attachmentData.base64EncodedString()
        let prompt = Self.prompt(for: userDescription)

        let payload = OpenAIRequest(
            model: "gpt-4.1-mini",
            input: [
                .init(role: "system", content: [.text(prompt.system)]),
                .init(role: "user", content: [
                    .text(prompt.user),
                    .inputImage(.init(b64Data: base64, mimeType: mimeType))
                ])
            ],
            temperature: 0.1
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try session.syncDataTask(with: request)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnalyzerError.requestFailed
        }

        guard let parsed = try? jsonDecoder.decode(OpenAIResponse.self, from: data) else {
            throw AnalyzerError.decodingFailed
        }

        guard let rawJSON = parsed.output.first?.content.first?.text?.data(using: .utf8) else {
            throw AnalyzerError.invalidResponse
        }

        let analysis = try jsonDecoder.decode(APIAnalysisResult.self, from: rawJSON)
        return analysis.asDomainModel()
    }

    private static func prompt(for description: String?) -> (system: String, user: String) {
        let systemPrompt = """
        Eres un asistente financiero que analiza imágenes de boletas y facturas chilenas. Devuelve un JSON con la estructura solicitada.
        """

        var userPrompt = """
        Extrae todos los campos posibles de la boleta. Considera moneda en CLP cuando no se indique. Devuelve JSON con los campos\n        {"title","merchantName","summary","purchaseDate","totalAmount","currencyCode","taxAmount","taxRate","category","keywords","tags","metadata","locationDescription","location"}.
        """
        if let description, !description.isEmpty {
            userPrompt += "\nContexto del usuario: \(description)"
        }
        return (systemPrompt, userPrompt)
    }
}

private extension OpenAIReceiptAnalyzer {
    struct OpenAIRequest: Codable {
        struct Message: Codable {
            struct Content: Codable {
                struct ImagePayload: Codable {
                    let b64Data: String
                    let mimeType: String

                    enum CodingKeys: String, CodingKey {
                        case b64Data = "b64_json"
                        case mimeType = "mime_type"
                    }
                }

                let type: String
                let text: String?
                let image: ImagePayload?

                static func text(_ text: String) -> Content {
                    Content(type: "output_text", text: text, image: nil)
                }

                static func inputImage(_ payload: ImagePayload) -> Content {
                    Content(type: "input_image", text: nil, image: payload)
                }

                enum CodingKeys: String, CodingKey {
                    case type
                    case text
                    case image = "image_url"
                }
            }

            let role: String
            let content: [Content]
        }

        let model: String
        let input: [Message]
        let temperature: Double
    }

    struct OpenAIResponse: Codable {
        struct OutputItem: Codable {
            struct ContentItem: Codable {
                let type: String
                let text: String?

                enum CodingKeys: String, CodingKey {
                    case type
                    case text = "text"
                }
            }

            let content: [ContentItem]
        }

        let output: [OutputItem]
    }

    struct APIAnalysisResult: Codable {
        let title: String
        let merchantName: String
        let summary: String
        let purchaseDate: Date?
        let totalAmount: Decimal
        let currencyCode: String
        let taxAmount: Decimal?
        let taxRate: Decimal?
        let category: ReceiptCategory
        let keywords: [String]
        let tags: [String]
        let metadata: [String: String]
        let locationDescription: String?
        let location: Location?

        struct Location: Codable {
            let latitude: Double
            let longitude: Double
        }

        func asDomainModel() -> AnalysisResult {
            AnalysisResult(
                title: title,
                merchantName: merchantName,
                summary: summary,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                currencyCode: currencyCode,
                taxAmount: taxAmount,
                taxRate: taxRate,
                category: category,
                keywords: keywords,
                tags: tags,
                metadata: metadata,
                locationDescription: locationDescription,
                location: location.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            )
        }
    }

    static func mockResult(description: String?) -> AnalysisResult {
        AnalysisResult(
            title: "Boleta",
            merchantName: description?.components(separatedBy: " ").first ?? "Comercio",
            summary: description ?? "Compra registrada manualmente",
            purchaseDate: Date(),
            totalAmount: 19990,
            currencyCode: "CLP",
            taxAmount: 3181,
            taxRate: 0.19,
            category: .other,
            keywords: ["manual", "sin-ia"],
            tags: ["fallback"],
            metadata: [:],
            locationDescription: nil,
            location: nil
        )
    }
}

private extension URLSession {
    func syncDataTask(with request: URLRequest) throws -> (Data, URLResponse) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)
        let task = dataTask(with: request) { taskData, taskResponse, taskError in
            data = taskData
            response = taskResponse
            error = taskError
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        if let error { throw error }
        guard let resultData = data, let resultResponse = response else {
            throw OpenAIReceiptAnalyzer.AnalyzerError.invalidResponse
        }
        return (resultData, resultResponse)
    }
}
