import Foundation

import iAsync_utils

public class JSocialError : Error {
    
    func iAsyncErrorsDomain() -> String {
        
        return "com.just_for_fun.social.library"
    }
}
