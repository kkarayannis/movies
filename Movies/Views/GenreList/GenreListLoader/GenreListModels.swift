import Foundation

struct GenreListResponse: Decodable {
    let genres: [Genre]
}

struct Genre: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
}
