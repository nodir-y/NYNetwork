
import Foundation
import Alamofire

internal class Monitor {
    internal private(set) var response: AFDataResponse<Any>
    
    internal init(_ response: AFDataResponse<Any>) {
        self.response = response
    }
    
    internal var statusCode: Int? {
        response.response?.statusCode
    }
    
    internal var decryptedData: Data? {
        response.data
    }
    
    internal var result: Result<Any, AFError> {
        response.result
    }
}
