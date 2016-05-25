import Foundation

import iAsync_utils

public class JSocialError : Error {

    public override class func iAsyncErrorsDomain() -> String {

        return "com.just_for_fun.social.library"
    }
}
