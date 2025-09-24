import Foundation
import Combine

/// Supplies dashboard views with summaries, trends and derived analytics.
final class DashboardViewModel: ObservableObject {
    @Published private(set) var summary: AnalyticsSummary?

    private var cancellable: AnyCancellable?

    func bind(to analyticsService: ReceiptAnalyticsService) {
        cancellable = analyticsService.$monthlySummary
            .assign(to: &$summary)
    }
}
