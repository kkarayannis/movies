import SwiftUI

struct GenreListView: View {
    let viewModel: GenreListViewModel
    
    @State private var genres: [Genre] = []
    
    var body: some View {
        List(genres) { genre in
            NavigationLink(value: PageType.movieList(genre: genre)) {
                Text(verbatim: genre.name)
            }
        }
        .onReceive(viewModel.genresPublisher) {
            genres = $0
        }
    }
}
