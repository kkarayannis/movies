import Combine
import SwiftUI

import PageLoader

final class MovieListPage: Page {
    private let viewModel: MovieListViewModel
    
    init(viewModel: MovieListViewModel) {
        self.viewModel = viewModel
    }
    
    var view: MovieListView {
        MovieListView(viewModel: viewModel)
    }
    
    var title: String {
        viewModel.title
    }
    
    var loadingStatePublisher: AnyPublisher<PageLoaderState, Never> {
        viewModel.pageStatePublisher
    }
    
    var titleDisplayMode: ToolbarTitleDisplayMode {
        .inline
    }
    
    func load() {
        viewModel.loadMovies()
    }
}
