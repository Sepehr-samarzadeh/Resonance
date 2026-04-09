import Foundation
import MusicKit
internal import Combine


class MusicChartViewModel: ObservableObject {
    @Published var songCharts: [MusicCatalogChart<Song>] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    func fetchCharts() async {
        isLoading = true
        do {
            let request = MusicCatalogChartsRequest(kinds: [.mostPlayed], types: [Song.self])
            let response = try await request.response()
            songCharts = response.songCharts
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

