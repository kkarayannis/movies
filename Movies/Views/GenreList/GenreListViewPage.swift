import Combine
import SwiftUI

import PageLoader

final class GenreListPage: Page {
    private let viewModel: GenreListViewModel
    
    init(viewModel: GenreListViewModel) {
        self.viewModel = viewModel
    }
    
    var view: AnyView {
        AnyView(GenreListView(viewModel: viewModel))
    }
    
    var title: String {
        viewModel.title
    }
    
    var loadingStatePublisher: AnyPublisher<PageLoaderState, Never> {
        viewModel.pageStatePublisher
    }
    
    var titleDisplayMode: ToolbarTitleDisplayMode {
        .automatic
    }
    
    func load() {
        viewModel.loadGenres()
    }
}
