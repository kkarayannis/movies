import SwiftUI

struct MovieListView: View {
    let viewModel: MovieListViewModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var movies: [Movie] = []
    
    private var twoColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }
    
    private var fourColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    }
    
    private var columns: [GridItem] {
#if os(tvOS)
        fourColumns
#else
        switch horizontalSizeClass {
        case .compact:
            twoColumns
        case .regular:
            fourColumns
        default:
            twoColumns
        }
#endif
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
                    .focusable()
                    .onAppear {
                        viewModel.handleOnAppear(movieID: movie.id)
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
