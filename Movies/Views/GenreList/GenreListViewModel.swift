import Combine
import Foundation

import PageLoader

final class GenreListViewModel {
    private let genreListLoader: GenreListLoader
    private let logger: Logger
    
    @Published private var genresResult: Result<[Genre], Error>?
    private var cancellable: AnyCancellable?
    
    init(genreListLoader: GenreListLoader, logger: Logger) {
        self.genreListLoader = genreListLoader
        self.logger = logger
    }
    
    var title: String {
        String(localized: "TMDB")
    }
    
    lazy var genresPublisher: AnyPublisher<[Genre], Never> = $genresResult
        .compactMap { result in
            switch result {
            case .success(let genres):
                return genres
            case .failure, .none:
                return nil
            }
        }
        .removeDuplicates { lhs, rhs in
            let lhsIDs = lhs.map(\.id)
            let rhsIDs = rhs.map(\.id)
            
            return lhsIDs == rhsIDs
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    
    lazy var pageStatePublisher: AnyPublisher<PageLoaderState, Never> = $genresResult
        .tryCompactMap { result in
            switch result {
            case .success(let genres):
                return genres
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
    
    func loadGenres() {
        cancellable = genreListLoader.genresPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let failure) = completion {
                    self?.logger.log(failure.localizedDescription, logLevel: .error)
                    self?.genresResult = .failure(failure)
                }
            }, receiveValue: { [weak self] genres in
                self?.genresResult = .success(genres)
            })
    }
}
