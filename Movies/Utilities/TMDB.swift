import Foundation

enum TMDB {
    static let apiKey = "API KEY HERE"
    
    enum Endpoint {
        static var imagesBase: String {
            "https://image.tmdb.org/t/p/w500"
        }
        
        static var genres: String {
            "https://api.themoviedb.org/3/genre/movie/list?api_key=\(TMDB.apiKey)"
        }
        
        static func genreMovies(_ genreID: Int, page: Int) -> String {
            "https://api.themoviedb.org/3/genre/\(genreID)/movies?api_key=\(TMDB.apiKey)&page=\(page)"
        }
    }
}
