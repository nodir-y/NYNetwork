
import Foundation
import Alamofire

public extension Notification.Name {
    static let iWonAuthError = Notification.Name(rawValue: "iWonAuthError")
}

public final class NetworkMonitor {
    internal typealias AFResponse = AFDataResponse<Any>
    internal typealias Completion<Model, ErrorModel: Codable> = (Result<Model, NYError<ErrorModel>>) -> Void
    internal typealias Finish<Model, ErrorModel: Codable> = Result<Model, NYError<ErrorModel>>
    internal typealias ClassFinish<Model, ErrorModel: Codable> = Result<[Model], NYError<ErrorModel>>
    internal typealias Kind<Model> = Model.Type
    
    public init() {}
    
    public static var errorRecorder: ((_ error: NYError<CRExternalError>) -> Void)?
    public static var unauthorizedUserHandler: (() -> Void)?
    
    /**
     Analyzes response object and decodes decodable object concluding on success or error
     
     - Parameters:
     - response: The response returned by server
     - kind: The decodable object type
     - completion: The callback called after monitor finish
     */
    internal func monitor<Model: Codable, ErrorModel: Codable>(_ response: AFResponse,
                                          kind: Kind<Model>,
                                          errorKind: Kind<ErrorModel>,
                                          completion: @escaping Completion<Model, ErrorModel>,
                                          onEmptySuccessResult: (() -> Void)? = nil) {
        let monitor = Monitor(response)
        inspectStatusCode(monitor, kind: kind, errorKind: errorKind, completion: completion, onEmptySuccessResult: onEmptySuccessResult)
    }
    
}


private extension NetworkMonitor {
    
    func inspectStatusCode<Model: Codable, ErrorModel: Codable>(_ monitor: Monitor,
                                           kind: Kind<Model>,
                                           errorKind: Kind<ErrorModel>,
                                           completion: @escaping Completion<Model, ErrorModel>,
                                           onEmptySuccessResult: (() -> Void)? = nil) {
        do {
            let statusCode = try statusCodeFor(response: monitor.response)
            
            if statusCode == 0 {
                onEmptySuccessResult?()
            }
            
            if statusCode == 401 {
                NotificationCenter.default.post(name: .iWonAuthError, object: nil)
            }
            
            if statusCode >= 400 {
                LogManager.log(statusCode: statusCode, monitor.response, kind)
                
                if statusCode <= 422 {
                    return internalError(from: monitor.decryptedData, kind: kind, errorKind: errorKind, statusCode: statusCode, completion: completion)
                } else {                    
                    return externalError(from: monitor.decryptedData, kind: kind, completion: completion)
                }
            } else {
                inspectDecode(monitor, kind: kind, errorKind: errorKind, completion: completion, onEmptySuccessResult: onEmptySuccessResult)
            }
        } catch {
            fire(error, kind: kind, completion: completion)
        }
    }
    
    func inspectDecode<Model: Codable, ErrorModel: Codable>(_ monitor: Monitor,
                                       kind: Kind<Model>,
                                       errorKind: Kind<ErrorModel>,
                                       completion: @escaping Completion<Model, ErrorModel>,
                                       onEmptySuccessResult: (() -> Void)? = nil) {
        let decodableModel: Model
        do {
            // Output log
            LogManager.log(statusCode: monitor.statusCode!, monitor.response, kind)
            
            // Check if response data is nil
            guard monitor.decryptedData != nil else {
                onEmptySuccessResult?()
                return
            }
            
            decodableModel = try decode(monitor.decryptedData, with: monitor.result)
            finish(decodableModel, kind: kind, completion: completion)
        } catch {
            internalError(from: monitor.decryptedData, kind: kind, errorKind: errorKind, completion: completion)
        }
    }
    
    func finish<Model, ErrorModel: Codable>(_ model: Model, kind: Kind<Model>, completion: @escaping Completion<Model, ErrorModel>) {
        DispatchQueue.main.async {
            completion(.success(model))
        }
    }
    
}


// MARK: - Inspector supporting methods
fileprivate extension NetworkMonitor {
    
    func statusCodeFor(response: AFResponse) throws -> Int {
        guard let statusCode = response.response?.statusCode else {
            throw appError("Response without status code")
        }
        return statusCode
    }
    
    func decode<Model: Codable>(_ data: Data?, with result: Result<Any, AFError>) throws -> Model {
        guard let data = data else { throw appError("Response data is nil") }
        do {
            switch result {
            case .success:
                return try NetworkHelper.decode(from: data)
                
            case let .failure(error):
                throw NYError<BlankModel>.unexpected(description: error.localizedDescription, data: data)
            }
        } catch {
            throw appError("Failure of «Decoding» a «Decrypted data» to common JSON body. \(error.localizedDescription)")
        }
    }
    
    func externalError<Model: Codable, ErrorModel: Codable>(from data: Data?, kind: Kind<Model>, completion: @escaping Completion<Model, ErrorModel>) {
        do {
            let error: ErrorModel = try NetworkHelper.decode(from: data)
            let appError: NYError<ErrorModel> = .standard(statusCode: 500, model: error)
//            NetworkMonitor.errorRecorder?(appError)
            completion(.failure(appError))
        } catch {
            completion(.failure(.unexpected(description: error.localizedDescription, data: data)))
        }
    }
    
    func internalError<Model: Codable, ErrorModel: Codable>(from data: Data?, kind: Kind<Model>, errorKind: Kind<ErrorModel>, statusCode: Int = 400, completion: @escaping Completion<Model, ErrorModel>) {
        do {
            let errorModel: ErrorModel = try NetworkHelper.decode(from: data)
            let appError: NYError<ErrorModel> = .standard(statusCode: statusCode, model: errorModel)
//            NetworkMonitor.errorRecorder?(appError)
            completion(.failure(appError))
        } catch {
            completion(.failure(.unexpected(description: error.localizedDescription, data: data)))
        }
    }
    
    func fire<Model, ErrorModel: Codable>(_ error: Error, kind: Kind<Model>, completion: @escaping Completion<Model, ErrorModel>) {
        if let reason = error as? NYError<ErrorModel> { // TODO: fix
            DispatchQueue.main.async {
                completion(.failure(reason))
            }
        } else {
            completion(.failure(.unexpected(description: error.localizedDescription, data: nil)))
        }
//        NetworkMonitor.errorRecorder?(reason)
    }
    
    func appError(_ title: String) -> NYError<CRExternalError> {
        NYError.unexpected(description: LogManager.describe(NetworkMonitor.self, with: title), data: nil)
    }
    
}
