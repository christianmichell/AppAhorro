import SwiftUI
import Charts

/// Connects the dashboard SwiftUI views with their observable view model.
struct DashboardContainerView: View {
    @EnvironmentObject private var analytics: ReceiptAnalyticsService
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        DashboardView(summary: viewModel.summary)
            .onAppear {
                viewModel.bind(to: analytics)
            }
    }
}

/// Presents aggregated information about the user's spending.
struct DashboardView: View {
    let summary: AnalyticsSummary?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let summary {
                        TotalCard(summary: summary)
                        CategoryChart(summary: summary)
                        DailyChart(summary: summary)
                        KeywordCloud(summary: summary)
                    } else {
                        PlaceholderView()
                    }
                }
                .padding()
            }
            .navigationTitle("Resumen financiero")
        }
    }
}

private struct TotalCard: View {
    let summary: AnalyticsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gasto del mes")
                .font(.headline)
            Text(formattedAmount(summary.totalSpent, currency: "CLP"))
                .font(.system(size: 34, weight: .bold))
            Text("IVA pagado: \(formattedAmount(summary.taxPaid, currency: "CLP"))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(radius: 4))
    }
}

private struct CategoryChart: View {
    let summary: AnalyticsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gasto por categoría")
                .font(.headline)
            Chart(summary.categoryBreakdown) { item in
                BarMark(
                    x: .value("Total", item.totalDouble),
                    y: .value("Categoría", item.id.title)
                )
                .foregroundStyle(by: .value("Categoría", item.id.title))
            }
            .frame(height: max(200, CGFloat(summary.categoryBreakdown.count) * 32))
        }
    }
}

private struct DailyChart: View {
    let summary: AnalyticsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gasto diario")
                .font(.headline)
            Chart(summary.dailySpending) { item in
                LineMark(
                    x: .value("Fecha", item.date),
                    y: .value("Total", item.totalDouble)
                )
                PointMark(
                    x: .value("Fecha", item.date),
                    y: .value("Total", item.totalDouble)
                )
            }
            .frame(height: 240)
        }
    }
}

private struct KeywordCloud: View {
    let summary: AnalyticsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Palabras clave destacadas")
                .font(.headline)
            if summary.keywords.isEmpty {
                Text("Aún no hay palabras clave generadas. Sube nuevas boletas para ver tendencias.")
                    .foregroundStyle(.secondary)
            } else {
                FlexibleKeywordGrid(keywords: summary.keywords)
            }
        }
    }
}

private struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No hay datos suficientes")
                .font(.title3)
            Text("Carga boletas para desbloquear el análisis automático de tus gastos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

private func formattedAmount(_ value: Decimal, currency: String) -> String {
    FormatterFactory.currencyFormatter(for: currency).string(from: value as NSDecimalNumber) ?? "--"
}

private extension AnalyticsSummary.CategoryBreakdown {
    var totalDouble: Double { NSDecimalNumber(decimal: total).doubleValue }
}

private extension AnalyticsSummary.DailySpend {
    var totalDouble: Double { NSDecimalNumber(decimal: total).doubleValue }
}
