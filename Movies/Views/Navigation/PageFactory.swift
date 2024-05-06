import Foundation

import ImageLoader
import PageLoader

enum PageType: Hashable {
    case genreList
    case movieList(genre: Genre)
}

/// Responsible for creating pages.
protocol PageFactory {
    /// Creates page for a certain type.
    /// - Parameter type: The page type that will be created.
    /// - Returns: A Page for a given type that will be used by PageLoader.
    func createPage(for type: PageType) -> any Page
}

final class PageFactoryImplementation: PageFactory {
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
    
    func createPage(for type: PageType) -> Page {
        switch type {
        case .genreList:
            createGenreListPage()
        case .movieList(let genre):
            createMovieListPage(genre: genre)
        }
    }
    
    private func createGenreListPage() -> any Page {
        let viewModel = GenreListViewModel(genreListLoader: genreListLoader, logger: logger)
        return GenreListPage(viewModel: viewModel)
    }
    
    private func createMovieListPage(genre: Genre) -> any Page {
        let viewModel = MovieListViewModel(
            genre: genre,
            movieListLoader: movieListLoader,
            imageLoader: imageLoader,
            logger: logger
        )
        return MovieListPage(viewModel: viewModel)
    }
}
