import SwiftUI
import MusicKit
struct MusicChartView: View {
    @StateObject private var viewModel = MusicChartViewModel()
    var body: some View {
        ScrollView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                }
                ForEach(viewModel.songCharts) { songChart in
                    ForEach(songChart.items) { song in
                        HStack {
                            if let artwork = song.artwork {
                                ArtworkImage(artwork,width: 60)
                                    .cornerRadius(10)
                                    .padding(10)
                                Spacer()
                                Text(song.artistName)
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .foregroundColor(.secondary)
                                    .padding(10)
                                Text(song.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .padding(10)
                            }
                            
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchCharts()
            }
        }
    }
}
