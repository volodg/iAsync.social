import Foundation

public class JFacebookRequestPublishingAccessError : JFacebookError {
    
    required public init() {
        super.init(description: "FACEBOOK_GET_PUBLISH_PERMISSON_ERROR")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}