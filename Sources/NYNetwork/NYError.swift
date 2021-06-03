
import Foundation

public enum NYError<ErrorModel: Codable>: Swift.Error {
    /// The error send by backend
    case standard(statusCode: Int, model: ErrorModel? = nil)
    /// Error handled in iOS app
    case technical(title: String, description: String)
    /// Unhandled error
    case unexpected(description: String, data: Data?)
    /// No network connection
    case unableToConnect
    
    public var localizedDescription: String {
        switch self {
        case .standard(let statusCode, _):
            return "Status code:: \(statusCode)"
            
        case let .technical(title, description):
            return "\(title)\n\(description)"
            
        case .unexpected(let description, _):
            return description
            
        case .unableToConnect:
            return "Unable to connect to network\nCheck if you have Wi-Fi or mobile Internet enabled, and try again"
        }
    }
}
