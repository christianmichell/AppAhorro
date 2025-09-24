import SwiftUI

/// Main entry view with dashboard, receipts list, assistant and settings tabs.
struct RootTabView: View {
    @EnvironmentObject private var receiptStore: ReceiptStore
    @EnvironmentObject private var analytics: ReceiptAnalyticsService

    var body: some View {
        TabView {
            DashboardContainerView()
                .tabItem {
                    Label("Resumen", systemImage: "chart.pie.fill")
                }

            ReceiptListContainerView()
                .tabItem {
                    Label("Boletas", systemImage: "tray.full.fill")
                }

            AssistantContainerView()
                .tabItem {
                    Label("Asistente", systemImage: "sparkles")
                }

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
        }
        .tint(.accentColor)
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environmentObject(ReceiptStore())
            .environmentObject(ReceiptAnalyticsService())
            .environmentObject(ReceiptQueryEngine())
            .environmentObject(AssistantViewModel())
    }
}
