
import Foundation

internal class NetworkHelper {
    
    /**
     Decodes data to decodable object
     
     - Parameters:
     - type: Decodable object type
     - data: Encoded data
     */
    @nonobjc class func decode<Model: Codable>(from data: Data?) throws -> Model {
        guard let data = data else { throw Error.encodedDataNotFound }
        
        do {
            // Decode data into codable model
            let decoded_object = try JSONDecoder().decode(Model.self, from: data)
            return decoded_object
        } catch {
            print(error)
            throw Error.decodeFailure(description: error.localizedDescription)
        }
    }
}


internal extension NetworkHelper {
    
    enum Error: Swift.Error {
        case encodedDataNotFound
        case decodeFailure(description: String)
    }
    
}

internal func choose<T>(_ data: T?, _ certain: T) -> T {
    guard let data = data else { return certain }
    return data
}
