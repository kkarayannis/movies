import Combine
import SwiftUI

/// The different states that a loadable page can be in.
public enum PageLoaderState {
    case loading
    case loaded
    case error
}

/// Interface for a loadable page.
public protocol Page<Content> {
    associatedtype Content: View
    var view: Content { get }
    var title: String { get }
    var loadingStatePublisher: AnyPublisher<PageLoaderState, Never> { get }
    var titleDisplayMode: ToolbarTitleDisplayMode { get }
    func load()
}

/// This view take care of the different state of loadable pages. It shows a loading indicator then the page is loading,
/// an error view if an error occurred and the page itself if it is loaded.
public struct PageLoader<Content: View>: View{
    let page: any Page<Content>
    @State private var state: PageLoaderState = .loading
    
    public init(page: any Page<Content>) {
        self.page = page
        
        page.load()
    }
    
    public var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
            case .loaded:
                page.view
            case .error:
                ErrorView() {
                    state = .loading
                    page.load()
                }
            }
        }
        .navigationTitle(page.title)
        .onReceive(page.loadingStatePublisher) {
            state = $0
        }
        .toolbarTitleDisplayMode(page.titleDisplayMode)
    }
}
