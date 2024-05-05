import SwiftUI

@main
struct MoviesApp: App {
    private let serviceProvider = ServiceProviderImplementation()
    
    var body: some Scene {
        WindowGroup {
            NavigationCoordinator(rootPageType: .genreList, pageFactory: serviceProvider.providePageFactory())
        }
    }
}
