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

private let cachedAsyncOp = JCachedAsync<HashableDictionary<String, NSObject>, FBSDKAccessToken, NSError>()

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

    public class func authFacebookAccessTokenStringLoader() -> AsyncTypes<String, NSError>.Async {
        
        let binder = { (session: FBSDKAccessToken) -> AsyncTypes<String, NSError>.Async in
            
            return async(value: session.tokenString)
        }
        
        return bindSequenceOfAsyncs(
            authFacebookAccessTokenLoader(),
            binder)
    }
    
    public class func authFacebookAccessTokenLoader() -> AsyncTypes<FBSDKAccessToken, NSError>.Async {
        
        return { (
            progressCallback: AsyncProgressCallback?,
            stateCallback   : AsyncChangeStateCallback?,
            doneCallback    : AsyncTypes<FBSDKAccessToken, NSError>.JDidFinishAsyncCallback?) -> JAsyncHandler in
            
            let permissions = Set(self.defaultAuthPermissions)
            
            let loader = jffFacebookLogin(permissions)
            
            let mergeObject: HashableDictionary<String,NSObject> = HashableDictionary([
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
    
    class func logoutLoaderWithRenewSystemAuthorization(renewSystemAuthorization: Bool) -> AsyncTypes<(), NSError>.Async {
        
        return { (
            progressCallback: AsyncProgressCallback?,
            stateCallback   : AsyncChangeStateCallback?,
            doneCallback    : AsyncTypes<(), NSError>.JDidFinishAsyncCallback?) -> JAsyncHandler in
            
            let accessToken = FBSDKAccessToken.currentAccessToken()
            
            let loader: AsyncTypes<(), NSError>.Async = accessToken != nil
                ?jffFacebookLogout(renewSystemAuthorization)
                :async(value: ())
            
            return loader(
                progressCallback: progressCallback,
                stateCallback   : stateCallback   ,
                finishCallback  : doneCallback)
        }
    }
    
    public class func userInfoLoader() -> AsyncTypes<SocialFacebookUser, NSError>.Async {
        
        let fields = ["id", "email", "name", "gender", "birthday", "picture", "bio"]
        
        return userInfoLoaderWithFields(fields)
    }
    
    public class func userInfoResponseLoader(fields: [String]) -> AsyncTypes<NSDictionary, NSError>.Async {
    
        let accessTokenLoader = authFacebookAccessTokenLoader()

        let userInfoLoader = { (accessToken: FBSDKAccessToken) -> AsyncTypes<NSDictionary, NSError>.Async in
    
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
    
    public class func userInfoLoaderWithFields(fields: [String]) -> AsyncTypes<SocialFacebookUser, NSError>.Async
    {
        let userInfoLoader = userInfoResponseLoader(fields)
        
        let parser = self.userParser()
            
        return bindSequenceOfAsyncs(userInfoLoader, parser)
    }
    
    public class func shareWithViewController(
        viewController: UIViewController,
        contentURL    : NSURL,
        usersIDs      : [String],
        title         : String) -> AsyncTypes<(), NSError>.Async
    {
        return jffShareFacebookDialog(
            viewController: viewController,
            contentURL    : contentURL    ,
            usersIDs      : usersIDs      ,
            title         : title)
    }
    
    class func graphLoaderWithPath(graphPath: String, accessToken: FBSDKAccessToken) -> AsyncTypes<NSDictionary, NSError>.Async
    {
        return graphLoaderWithPath(graphPath, parameters:nil, accessToken:accessToken)
    }
    
    public class func graphLoaderWithPath(
        graphPath: String, parameters: [String:AnyObject]?, accessToken: FBSDKAccessToken) -> AsyncTypes<NSDictionary, NSError>.Async
    {
        return graphLoaderWithPath(graphPath, httpMethod: "GET", parameters:parameters, accessToken:accessToken)
    }
    
    class func graphLoaderWithPath(
        graphPath  : String,
        httpMethod : String,
        parameters : [String:AnyObject]?,
        accessToken: FBSDKAccessToken) -> AsyncTypes<NSDictionary, NSError>.Async
    {
        let result = graphPath.stringByReplacingOccurrencesOfString(" ", withString:"+")
        let graphLoader = jffGenericFacebookGraphRequestLoader(accessToken: accessToken, graphPath: result, httpMethod: httpMethod, parameters: parameters)
        
        return graphLoader
    }
    
//    class func postImage(image: UIImage, message: String?) -> AsyncTypes<NSDictionary>.Async
//    {
//        let parameters: [String:AnyObject] =
//        [
//            "message" : message ?? "",
//            "image"   : UIImageJPEGRepresentation(image, 1.0)
//        ]
//        
//        let binder = { (session: FBSession) -> AsyncTypes<NSDictionary>.Async in
//            
//            return self.graphLoaderWithPath("me/photos", httpMethod: "POST", parameters: parameters, session:session)
//        }
//        
//        let getAccessLoader = publishStreamAccessSessionLoader()
//        
//        return bindSequenceOfAsyncs(getAccessLoader, binder)
//    }

    private class func userParser() -> AsyncTypes2<NSDictionary, SocialFacebookUser, NSError>.JAsyncBinder
    {
        let parser = { (result: NSDictionary) -> AsyncTypes<SocialFacebookUser, NSError>.Async in
            
            let result = SocialFacebookUser.createSocialFacebookUserWithJsonObject(result)
            return async(result: result)
        }
        
        return parser
    }
    
//    private class func usersParser() -> AsyncTypes2<NSDictionary, [SocialFacebookUser]>.JAsyncBinder {
//        
//        func parser(result: NSDictionary) -> AsyncTypes<[SocialFacebookUser]>.Async {
//            
//            print("result: \(result)")
//            func loadDataBlock() -> AsyncResult<[SocialFacebookUser]> {
//                
//                return JJsonValue.create(result) >>= { json -> AsyncResult<[SocialFacebookUser]> in
//                    
//                    return json.array("data") >>= { $0 >>= { elJson -> AsyncResult<SocialFacebookUser> in
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
    
//    public class func friendsLoaderWithFields(fields: [String], uid: String = "me") -> AsyncTypes<[SocialFacebookUser]>.Async {
//        
//        let authLoader = JSocialFacebook.authFacebookAccessTokenLoader()
//        
//        func binder(accessToken: FBSDKAccessToken) -> AsyncTypes<[SocialFacebookUser]>.Async {
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
