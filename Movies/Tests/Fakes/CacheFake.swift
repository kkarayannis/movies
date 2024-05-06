import Cache

final class CacheFake: Cache {
    var dataStored: Data?
    func store(data: Data, key: String) throws {
        dataStored = data
    }
    
    var dataToReturn: Data?
    func data(for key: String) throws -> Data? {
        dataToReturn
    }
}
