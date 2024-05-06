import Foundation

extension String {
    var base64: String {
        Data(utf8).base64EncodedString()
    }
}
