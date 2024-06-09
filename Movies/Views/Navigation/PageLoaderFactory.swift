import Foundation
import SwiftUI

import ImageLoader
import PageLoader

enum PageType: Hashable {
    case genreList
    case movieList(genre: Genre)
}

final class PageLoaderFactory {
    private let genreListLoader: GenreListLoader
    private let movieListLoader: MovieListLoader
    private let imageLoader: ImageLoader
    private let logger: Logger
    
    init(
        genreListLoader: GenreListLoader,
        movieListLoader: MovieListLoader,
        imageLoader: ImageLoader,
        logger: Logger
    ) {
        self.genreListLoader = genreListLoader
        self.movieListLoader = movieListLoader
        self.imageLoader = imageLoader
        self.logger = logger
    }
    
    @ViewBuilder
    func createPageLoader(for type: PageType) -> some View {
        switch type {
        case .genreList:
            createGenreListPageLoader()
        case .movieList(let genre):
            createMovieListPageLoader(genre: genre)
        }
    }
    
    private func createGenreListPageLoader() -> PageLoader<GenreListView> {
        let viewModel = GenreListViewModel(genreListLoader: genreListLoader, logger: logger)
        return PageLoader(page: GenreListPage(viewModel: viewModel))
    }
    
    private func createMovieListPageLoader(genre: Genre) -> PageLoader<MovieListView> {
        let viewModel = MovieListViewModel(
            genre: genre,
            movieListLoader: movieListLoader,
            imageLoader: imageLoader,
            logger: logger
        )
        return PageLoader(page: MovieListPage(viewModel: viewModel))
    }
}
