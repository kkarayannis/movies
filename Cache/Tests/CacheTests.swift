import XCTest
@testable import Cache

final class CacheTests: XCTestCase {

    // Unit under test
    private var cache: Cache!
    
    // Dependencies
    private var fileManagerFake: FileManagerFake!
    
    override func setUp() {
        super.setUp()
        fileManagerFake = FileManagerFake()
        cache = CacheImplementation(fileManager: fileManagerFake)
    }

    func testCacheWritesDataToDisk() throws {
        // Given some data
        let data = "key to my kingdom".data(using: .utf8)!
        
        // When that data is stored in the cache
        let key = "super-secret-key"
        try cache.store(data: data, key: key)
        
        // Then the data is stored
        guard let timestampedData = fileManagerFake.dataStored else {
            XCTFail("No data stored")
            return
        }
        let storedData = try JSONDecoder().decode(TimestampedData.self, from: timestampedData)
        XCTAssertEqual(storedData.data, data)
        XCTAssertTrue(fileManagerFake.pathStored?.hasSuffix(key) ?? false)
    }
    
    func testCacheReadsDataFromDisk() throws {
        // Given some data on the disk
        let data = "key to my kingdom".data(using: .utf8)!
        let timestampedData = TimestampedData(data: data)
        fileManagerFake.dataToReturn = try JSONEncoder().encode(timestampedData)
        
        // When the cache reads the data
        let key = "super-secret-key"
        let dataFetched = try cache.data(for: key)
        
        // Then the data fetched is correct
        XCTAssertEqual(dataFetched, data)
        
        // and the path that was used is correct
        XCTAssertTrue(fileManagerFake.pathToRead?.hasSuffix(key) ?? false)
    }
    
    func testCacheThrowsExceptionWhenWritingError() async throws {
        // Given some data
        let data = "key to my kingdom".data(using: .utf8)!
        
        // and the file manager will refuse to store the data
        fileManagerFake.boolToReturn = false
        
        // When that data is stored in the cache
        let key = "super-secret-key"
        do {
            try cache.store(data: data, key: key)
        } catch {
            // Then an exception is thrown.
            XCTAssertEqual(error as? CacheError, .cannotStoreData)
            return
        }
        
        XCTFail("Should not reach here")
    }

}
