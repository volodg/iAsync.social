import Foundation

import iAsync_utils

public class JSocialError : UtilsError {

    public override class func iAsyncErrorsDomain() -> String {

        return "com.just_for_fun.social.library"
    }
}
