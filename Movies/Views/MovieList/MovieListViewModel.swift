import Combine
import Foundation

import ImageLoader
import PageLoader

final class MovieListViewModel {
    private let genre: Genre
    private let movieListLoader: MovieListLoader
    private let imageLoader: ImageLoader
    private let logger: Logger
    
    @Published private var movies: [Movie] = []
    @Published private var latestMovieListResult: Result<GenreMoviesResponse, Error>?
    private var cancellable: AnyCancellable?
    
    init(genre: Genre, movieListLoader: MovieListLoader, imageLoader: ImageLoader, logger: Logger) {
        self.genre = genre
        self.movieListLoader = movieListLoader
        self.imageLoader = imageLoader
        self.logger = logger
    }
    
    var title: String {
        genre.name
    }
    
    lazy var moviesPublisher: AnyPublisher<[Movie], Never> = $movies
        .removeDuplicates { lhs, rhs in
            let lhsIDs = lhs.map(\.id)
            let rhsIDs = rhs.map(\.id)
            
            return lhsIDs == rhsIDs
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    
    lazy var pageStatePublisher: AnyPublisher<PageLoaderState, Never> = $latestMovieListResult
        .tryCompactMap { [weak self] result in
            switch result {
            case .success(let movies):
                return movies
            case .failure(let error):
                if self?.movies.isEmpty == false {
                    return nil // If a pagination request fails (page > 1), ignore error
                }
                throw error
            case .none:
                return nil
            }
        }
        .map { _ in .loaded } // If we receive any element, we consider the page loaded.
        .removeDuplicates()
        .replaceError(with: .error)
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    
    func loadMovies() {
        cancellable = movieListLoader.moviesPublisher(genreID: genre.id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let failure) = completion {
                    self?.logger.log(failure.localizedDescription, logLevel: .error)
                    self?.latestMovieListResult = .failure(failure)
                }
            }, receiveValue: { [weak self] response in
                self?.movies += response.results
                self?.latestMovieListResult = .success(response)
            })
    }
    
    func imageViewModel(for movie: Movie) -> ImageViewModel {
        ImageViewModel(
            url: URL(string: TMDB.Endpoint.imagesBase + movie.posterPath),
            imageLoader: imageLoader
        )
    }
    
}
