
import Foundation
import Alamofire

public typealias Completion<Model: Decodable, ErrorModel: Codable> = (Result<Model, NYError<ErrorModel>>) -> Void
public typealias CompletionArray<Model: Decodable, ErrorModel: Codable> = (Result<[Model], NYError<ErrorModel>>) -> Void

public class NetworkManager: NSObject {
    
    public static let shared = NetworkManager()
    
    public func makeRequest<Model: Codable, ErrorModel: Codable>(url: String, params: [String: Any] = [:], headers: HTTPHeaders = [], method: HTTPMethod = .get, completion: @escaping CompletionArray<Model, ErrorModel>) {
        
        let request = AF.request(url, method: method, parameters: params, headers: headers)
        
        let start = CFAbsoluteTimeGetCurrent()
        request.responseJSON { (response) in
            DispatchQueue.main.async {
                NetworkMonitor().monitor(response, kind: [Model].self, errorKind: ErrorModel.self, completion: completion) {
                    completion(.success([BlankModel()] as! [Model]))
                    print("empty success")
                }
                
                let finish = CFAbsoluteTimeGetCurrent()
                let time = finish - start
                print("Network request time: \(time)")
            }
        }
    }
    
    public func makeRequest<Model: Codable, ErrorModel: Codable>(url: String, params: [String: Any] = [:], headers: HTTPHeaders = [], method: HTTPMethod = .get, completion: @escaping Completion<Model, ErrorModel>) {
        
        let request = AF.request(url, method: method, parameters: params, headers: headers)
        
        let start = CFAbsoluteTimeGetCurrent()
        request.responseJSON { (response) in
            DispatchQueue.main.async {
                NetworkMonitor().monitor(response, kind: Model.self, errorKind: ErrorModel.self, completion: completion) {
                    completion(.success(BlankModel() as! Model))
                    print("empty success")
                }
                
                let finish = CFAbsoluteTimeGetCurrent()
                let time = finish - start
                print("Network request time: \(time)")
            }
        }
    }
    
    public func makeUpload<Model: Codable, ErrorModel: Codable>(_ multipartFormData: MultipartFormData, url: String, headers: HTTPHeaders = [], completion: @escaping Completion<Model, ErrorModel>) {
        
        let start = CFAbsoluteTimeGetCurrent()
        
        AF.upload(multipartFormData: multipartFormData, to: url, headers: headers).uploadProgress(closure: { (progress) in
            print("progress: \(progress.fractionCompleted)")
        }).responseJSON { (response) in
            print("responseJson")
            DispatchQueue.main.async {
                NetworkMonitor().monitor(response, kind: Model.self, errorKind: ErrorModel.self, completion: completion) {
                    print("empty success")
                }
            }
            let finish = CFAbsoluteTimeGetCurrent()
            let time = finish - start
            print("Network upload time: \(time)")
        }
    }
}
