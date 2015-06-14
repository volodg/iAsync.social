//
//  JSocialFacebook.swift
//  iAsync_social
//
//  Created by Vladimir Gorbenko on 08.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

//TODO import JJsonTools

import FBSDKLoginKit

private let cachedAsyncOp = JCachedAsync<HashableDictionary<String, NSObject>, FBSDKAccessToken>()

//TODO remove NSObject
public class JSocialFacebook: NSObject {

    private struct Static {
        static var defaultAuthPermissions = ["email", "user_birthday"]
    }
    
    public class var defaultAuthPermissions: [String] {
        get {
            return Static.defaultAuthPermissions
        }
        set {
            Static.defaultAuthPermissions = newValue
        }
    }
    
    public static func isActiveAccessToken() -> Bool {
        return FBSDKAccessToken.currentAccessToken() != nil
    }

    public class func authFacebookAccessTokenStringLoader() -> JAsyncTypes<String>.JAsync {
        
        let binder = { (session: FBSDKAccessToken) -> JAsyncTypes<String>.JAsync in
            
            return asyncWithResult(session.tokenString)
        }
        
        return bindSequenceOfAsyncs(authFacebookAccessTokenLoader(), binder)
    }
    
    public class func authFacebookAccessTokenLoader() -> JAsyncTypes<FBSDKAccessToken>.JAsync {
        
        return { (
            progressCallback: JAsyncProgressCallback?,
            stateCallback: JAsyncChangeStateCallback?,
            doneCallback: JAsyncTypes<FBSDKAccessToken>.JDidFinishAsyncCallback?) -> JAsyncHandler in
            
            let permissions = Set(self.defaultAuthPermissions)
            
            let loader = jffFacebookLogin(permissions)
            
            let mergeObject: HashableDictionary<String,NSObject> = HashableDictionary(dict:
                [
                    "methodName"  : __FUNCTION__,
                    "permissions" : Array(permissions)
                ])
            
            let cachedLoader = cachedAsyncOp.asyncOpMerger(loader, uniqueKey:mergeObject)
            
            return cachedLoader(
                progressCallback: progressCallback,
                stateCallback   : stateCallback,
                finishCallback  : doneCallback)
        }
    }
    
    class func logoutLoaderWithRenewSystemAuthorization(renewSystemAuthorization: Bool) -> JAsyncTypes<()>.JAsync {
        
        return { (
            progressCallback: JAsyncProgressCallback?,
            stateCallback   : JAsyncChangeStateCallback?,
            doneCallback    : JAsyncTypes<()>.JDidFinishAsyncCallback?) -> JAsyncHandler in
            
            let accessToken = FBSDKAccessToken.currentAccessToken()
            
            let loader: JAsyncTypes<()>.JAsync = accessToken != nil
                ?jffFacebookLogout(renewSystemAuthorization)
                :asyncWithResult(())
            
            return loader(
                progressCallback: progressCallback,
                stateCallback   : stateCallback   ,
                finishCallback  : doneCallback)
        }
    }
    
//    class func authFacebookSessionWithPublishPermissions(permissions: [String]) -> JAsyncTypes<FBSession>.JAsync {
//        
//        let loader = { (
//            progressCallback: JAsyncProgressCallback?,
//            stateCallback: JAsyncChangeStateCallback?,
//            doneCallback: JAsyncTypes<FBSession>.JDidFinishAsyncCallback?) -> JAsyncHandler in
//            
//            let session = self.facebookSession
//            
//            var currPermissions = Set(session.permissions as! [String])
//            
//            currPermissions.unionInPlace(permissions)
//            
//            let loader = jffFacebookLoginWithPublishPermissions(session, Array(currPermissions))
//            
//            let doneCallbackWrapper = { (result: Result<FBSession>) -> () in
//                
//                switch result {
//                case let .Value(v):
//                    self.facebookSession = v.value
//                default:
//                    break
//                }
//                
//                doneCallback?(result: result)
//            }
//            
//            return loader(
//                progressCallback: progressCallback,
//                stateCallback   : stateCallback   ,
//                finishCallback  : doneCallbackWrapper)
//        }
//        
//        let mergeParams: HashableDictionary<String, NSObject> = HashableDictionary(dict:
//        [
//            "methodName"  : __FUNCTION__,
//            "permissions" : Array(Set(permissions))
//        ])
//        return cachedAsyncOp.asyncOpMerger(loader, uniqueKey:mergeParams)
//    }
//    
//    class func publishStreamAccessSessionLoader() -> JAsyncTypes<FBSession>.JAsync {
//        
//        let authLoader = authFacebookSessionLoader()
//        
//        let binder = { (session: FBSession) -> JAsyncTypes<FBSession>.JAsync in
//            
//            let permissions = ["publish_stream", "user_birthday", "email"]
//            return jffFacebookPublishAccessRequest(session, permissions)
//        }
//        
//        return bindSequenceOfAsyncs(authLoader, binder)
//    }
    
    public class func userInfoLoader() -> JAsyncTypes<SocialFacebookUser>.JAsync {
        
        let fields = ["id", "email", "name", "gender", "birthday", "picture", "bio"]
        
        return userInfoLoaderWithFields(fields)
    }
    
    public class func userInfoResponseLoader(fields: [String]) -> JAsyncTypes<NSDictionary>.JAsync {
    
        let accessTokenLoader = authFacebookAccessTokenLoader()

        let userInfoLoader = { (accessToken: FBSDKAccessToken) -> JAsyncTypes<NSDictionary>.JAsync in
    
            let parameters: [String:String] = fields.count > 0
            ?["fields" : ",".join(fields)]
            :[:]
            
            return self.graphLoaderWithPath("me", parameters:parameters, accessToken:accessToken)
        }
    
        let loader = bindSequenceOfAsyncs(accessTokenLoader, userInfoLoader)
    
        let reloadSession = sequenceOfAsyncs(
            self.logoutLoaderWithRenewSystemAuthorization(true),
            accessTokenLoader)
        
        let reloadUser = sequenceOfAsyncs(reloadSession, loader)
        
        return trySequenceOfAsyncs(loader, reloadUser)
    }
    
    public class func userInfoLoaderWithFields(fields: [String]) -> JAsyncTypes<SocialFacebookUser>.JAsync
    {
        let userInfoLoader = userInfoResponseLoader(fields)
        
        let parser = self.userParser()
            
        return bindSequenceOfAsyncs(userInfoLoader, parser)
    }
    
    public class func shareWithViewController(
        viewController: UIViewController,
        contentURL    : NSURL,
        usersIDs      : [String],
        title         : String) -> JAsyncTypes<()>.JAsync
    {
        return jffShareFacebookDialog(
            viewController: viewController,
            contentURL    : contentURL    ,
            usersIDs      : usersIDs      ,
            title         : title)
    }
    
    class func graphLoaderWithPath(graphPath: String, accessToken: FBSDKAccessToken) -> JAsyncTypes<NSDictionary>.JAsync
    {
        return graphLoaderWithPath(graphPath, parameters:nil, accessToken:accessToken)
    }
    
    public class func graphLoaderWithPath(
        graphPath: String, parameters: [String:AnyObject]?, accessToken: FBSDKAccessToken) -> JAsyncTypes<NSDictionary>.JAsync
    {
        return graphLoaderWithPath(graphPath, httpMethod: "GET", parameters:parameters, accessToken:accessToken)
    }
    
    class func graphLoaderWithPath(
        graphPath  : String,
        httpMethod : String,
        parameters : [String:AnyObject]?,
        accessToken: FBSDKAccessToken) -> JAsyncTypes<NSDictionary>.JAsync
    {
        let result = graphPath.stringByReplacingOccurrencesOfString(" ", withString:"+")
        let graphLoader = jffGenericFacebookGraphRequestLoader(accessToken: accessToken, graphPath: result, httpMethod: httpMethod, parameters: parameters)
        
        return graphLoader
    }
    
//    class func postImage(image: UIImage, message: String?) -> JAsyncTypes<NSDictionary>.JAsync
//    {
//        let parameters: [String:AnyObject] =
//        [
//            "message" : message ?? "",
//            "image"   : UIImageJPEGRepresentation(image, 1.0)
//        ]
//        
//        let binder = { (session: FBSession) -> JAsyncTypes<NSDictionary>.JAsync in
//            
//            return self.graphLoaderWithPath("me/photos", httpMethod: "POST", parameters: parameters, session:session)
//        }
//        
//        let getAccessLoader = publishStreamAccessSessionLoader()
//        
//        return bindSequenceOfAsyncs(getAccessLoader, binder)
//    }

    private class func userParser() -> JAsyncTypes2<NSDictionary, SocialFacebookUser>.JAsyncBinder
    {
        let parser = { (result: NSDictionary) -> JAsyncTypes<SocialFacebookUser>.JAsync in
            
            let result = SocialFacebookUser.createSocialFacebookUserWithJsonObject(result)
            return asyncWithJResult(result)
        }
        
        return parser
    }
    
//    private class func usersParser() -> JAsyncTypes2<NSDictionary, [SocialFacebookUser]>.JAsyncBinder {
//        
//        func parser(result: NSDictionary) -> JAsyncTypes<[SocialFacebookUser]>.JAsync {
//            
//            print("result: \(result)")
//            func loadDataBlock() -> Result<[SocialFacebookUser]> {
//                
//                return JJsonValue.create(result) >>= { json -> Result<[SocialFacebookUser]> in
//                    
//                    return json.array("data") >>= { $0 >>= { elJson -> Result<SocialFacebookUser> in
//                        
//                        return SocialFacebookUser.createSocialFacebookUserWithJsonObject(elJson)
//                    }}
//                }
//            }
//            
//            return asyncWithSyncOperation(loadDataBlock)
//        }
//        
//        return parser
//    }
    
//    public class func friendsLoaderWithFields(fields: [String], uid: String = "me") -> JAsyncTypes<[SocialFacebookUser]>.JAsync {
//        
//        let authLoader = JSocialFacebook.authFacebookAccessTokenLoader()
//        
//        func binder(accessToken: FBSDKAccessToken) -> JAsyncTypes<[SocialFacebookUser]>.JAsync {
//            
//            let graphPath = "/\(uid)/taggable_friends"
//            
//            let parameters =
//            [
//                "fields" : join(",", fields),
//                "limit"  : "10000"
//            ]
//            
//            let friendsLoader =  JSocialFacebook.graphLoaderWithPath(
//                graphPath, parameters:parameters, accessToken:accessToken)
//            
//            return bindSequenceOfAsyncs(friendsLoader, usersParser())
//        }
//        
//        let loader = bindSequenceOfAsyncs(authLoader, binder)
//        return logErrorForLoader(loader)
//    }
}
