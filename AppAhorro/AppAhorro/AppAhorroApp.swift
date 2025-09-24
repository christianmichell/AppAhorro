import SwiftUI

/// Entry point for the AppAhorro iOS application.
@main
struct AppAhorroApp: App {
    @StateObject private var receiptStore = ReceiptStore()
    @StateObject private var analyticsService = ReceiptAnalyticsService()
    @StateObject private var queryEngine = ReceiptQueryEngine()
    @StateObject private var aiAssistant = AssistantViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(receiptStore)
                .environmentObject(analyticsService)
                .environmentObject(queryEngine)
                .environmentObject(aiAssistant)
                .onAppear {
                    analyticsService.configure(with: receiptStore)
                    queryEngine.configure(with: receiptStore)
                    aiAssistant.configure(with: receiptStore, queryEngine: queryEngine)
                }
        }
    }
}
