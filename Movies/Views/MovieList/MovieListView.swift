import SwiftUI

struct MovieListView: View {
    let viewModel: MovieListViewModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var movies: [Movie] = []
    
    var columns: [GridItem] {
        switch horizontalSizeClass {
        case .compact:
            [GridItem(.flexible()), GridItem(.flexible())]
        case .regular:
            [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        default:
            [GridItem(.flexible()), GridItem(.flexible())]
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(movies) { movie in
                    VStack {
                        PosterView(viewModel: viewModel.imageViewModel(for: movie))
                        Text(verbatim: movie.title)
                            .lineLimit(3, reservesSpace: true)
                    }
                }
            }
            .padding([.leading, .trailing])
        }
        .onReceive(viewModel.moviesPublisher) {
            movies = $0
        }
    }
}
