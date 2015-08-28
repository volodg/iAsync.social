import Foundation

import FBSDKCoreKit
import FBSDKLoginKit

import iAsync_utils

public enum FbErrorType {
    
    case RequestLimitReached
    case Undefined
}

public class JFacebookError : JSocialError {
    
    let nativeError: NSError
    
    init(nativeError: NSError) {
        
        self.nativeError = nativeError
        super.init(description: "JFacebookError")
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func iAsyncErrorsDomain() -> String {
        return "com.just_for_fun.facebook.library"
    }
    
    public override var localizedDescription: String {
        
        if let descr = self.nativeError.userInfo["NSLocalizedRecoverySuggestion"] as? String {
            return descr
        }
        
        return nativeError.localizedDescription
    }
    
    public lazy var fbErrorType: FbErrorType = { [unowned self] () -> FbErrorType in
        
        if let descr = self.nativeError.userInfo["com.facebook.sdk:FBSDKErrorDeveloperMessageKey"] as? String {
            
            let table: [String:FbErrorType] = [
                "(#4) Application request limit reached" : FbErrorType.RequestLimitReached
            ]
            
            return table[descr] ?? .Undefined
        }
        
        return .Undefined
    }()
    
    public override var errorLogDescription: String? {
        
        switch fbErrorType {
        case .RequestLimitReached:
            return nil
        case .Undefined:
            return super.errorLogDescription
        }
    }
}
