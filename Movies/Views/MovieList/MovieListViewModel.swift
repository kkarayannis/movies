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
    
    private var currentPage: Int {
        switch latestMovieListResult {
        case .success(let result):
            return result.page
        case .failure, nil:
            return 0
        }
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
        cancellable = movieListLoader.moviesPublisher(genreID: genre.id, page: currentPage + 1)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let failure) = completion {
                    self?.logger.log(failure.localizedDescription, logLevel: .error)
                    if self?.movies.isEmpty == false {
                        return // If a pagination request fails (page > 1), ignore failure
                    }
                    self?.latestMovieListResult = .failure(failure)
                }
            }, receiveValue: { [weak self] response in
                if response.page == 1 {
                    self?.movies = response.results
                } else {
                    // Let's be safe and check that we never add the same movie twice because SwiftUI really doesn't
                    // like that.
                    response.results.forEach { newMovie in
                        if self?.movies.contains(where: { $0.id == newMovie.id }) == false {
                            self?.movies.append(newMovie)
                        }
                    }
                }
                self?.latestMovieListResult = .success(response)
            })
    }
    
    func imageViewModel(for movie: Movie) -> ImageViewModel {
        ImageViewModel(
            url: URL(string: TMDB.Endpoint.imagesBase + movie.posterPath),
            imageLoader: imageLoader
        )
    }
    
    func handleOnAppear(movieID: Int) {
        if movieID == movies.last?.id {
            loadMovies()
        }
    }
    
}
