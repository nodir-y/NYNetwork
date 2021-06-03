
public struct BlankModel: Codable {
    
}

public struct CRExternalError: Codable {
    public var message: String?
}

public struct CRInternalError: Codable {
    public var code: String? = nil
    public var data: String? = nil
    public var message: String? = nil
}
