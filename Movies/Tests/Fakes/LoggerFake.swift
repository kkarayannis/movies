import Foundation
@testable import Movies

final class LoggerFake: Logger {
    var logged: [String: LogLevel] = [:]
    
    func log(_ message: String, logLevel: LogLevel) {
        logged[message] = logLevel
    }
}
