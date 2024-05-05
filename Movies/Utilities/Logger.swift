import Foundation
import os

enum LogLevel {
    case info
    case debug
    case error
    case warning
}

protocol Logger {
    func log(_ message: String, logLevel: LogLevel)
}

final class LoggerImplementation: Logger {
    private let logger = os.Logger()
    
    func log(_ message: String, logLevel: LogLevel) {
        switch logLevel {
        case .info:
            logger.info("\(message)")
        case .debug:
            logger.debug(("\(message)"))
        case .error:
            logger.error("\(message)")
        case .warning:
            logger.warning("\(message)")
        }
    }
}
