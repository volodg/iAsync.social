//
//  SocialFacebook.swift
//  iAsync_social
//
//  Created by Vladimir Gorbenko on 08.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import FBSDKLoginKit

private let cachedAsyncOp = CachedAsync<HashableDictionary<String, NSObject>, FBSDKAccessToken, NSError>()

final public class SocialFacebook {

    public static func isActiveAccessToken() -> Bool {
        return FBSDKAccessToken.currentAccessToken() != nil
    }

    public static func authFacebookAccessTokenStringLoader(authPermissions: [String], rootVC: UIViewController) -> AsyncTypes<String, NSError>.Async {
        
        let binder = { (session: FBSDKAccessToken) -> AsyncTypes<String, NSError>.Async in
            return async(value: session.tokenString)
        }
        
        return bindSequenceOfAsyncs(
            authFacebookAccessTokenLoader(authPermissions, rootVC: rootVC),
            binder)
    }
    
    public static func authFacebookAccessTokenLoader(authPermissions: [String], rootVC: UIViewController) -> AsyncTypes<FBSDKAccessToken, NSError>.Async {
        
        return { (
            progressCallback: AsyncProgressCallback?,
            stateCallback   : AsyncChangeStateCallback?,
            doneCallback    : AsyncTypes<FBSDKAccessToken, NSError>.DidFinishAsyncCallback?) -> AsyncHandler in
            
            let permissions = Set(authPermissions)
            
            let loader = FBApi.loginLoader(permissions, rootVC: rootVC)
            
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
    
    public static func currentAccessToken() -> FBSDKAccessToken? {
        
        let accessToken = FBSDKAccessToken.currentAccessToken()
        return accessToken
    }
    
    public static func logoutLoaderWithRenewSystemAuthorization(renewSystemAuthorization: Bool) -> AsyncTypes<(), NSError>.Async {
        
        return { (
            progressCallback: AsyncProgressCallback?,
            stateCallback   : AsyncChangeStateCallback?,
            doneCallback    : AsyncTypes<(), NSError>.DidFinishAsyncCallback?) -> AsyncHandler in
            
            let accessToken = FBSDKAccessToken.currentAccessToken()
            
            let loader: AsyncTypes<(), NSError>.Async = accessToken != nil
                ?facebookLogout(renewSystemAuthorization)
                :async(value: ())
            
            return loader(
                progressCallback: progressCallback,
                stateCallback   : stateCallback   ,
                finishCallback  : doneCallback)
        }
    }
    
    public static func userInfoLoader(authPermissions: [String], rootVC: UIViewController) -> AsyncTypes<SocialFacebookUser, NSError>.Async {
        
        let fields = ["id", "email", "name", "gender", "birthday", "picture", "bio"]
        return userInfoLoaderWithFields(fields, rootVC: rootVC, authPermissions: authPermissions)
    }
    
    public static func userInfoResponseLoader(
        fields         : [String],
        rootVC         : UIViewController,
        authPermissions: [String]) -> AsyncTypes<NSDictionary, NSError>.Async
    {
        let accessTokenLoader = authFacebookAccessTokenLoader(authPermissions, rootVC: rootVC)
        
        let userInfoLoader = { (accessToken: FBSDKAccessToken) -> AsyncTypes<NSDictionary, NSError>.Async in
            
            let parameters: [String:String] = fields.count > 0
                ?["fields" : fields.joinWithSeparator(",")]
                :[:]
            
            return self.graphLoaderWithPath("me", parameters:parameters, accessToken:accessToken)
        }
        
        let loader = bindSequenceOfAsyncs(accessTokenLoader, userInfoLoader)
        
        return loader
    }
    
    public static func userInfoLoaderWithFields(
        fields         : [String],
        rootVC         : UIViewController,
        authPermissions: [String]) -> AsyncTypes<SocialFacebookUser, NSError>.Async
    {
        let userInfoLoader = userInfoResponseLoader(fields, rootVC: rootVC, authPermissions: authPermissions)
        
        let parser = self.userParser()
            
        return bindSequenceOfAsyncs(userInfoLoader, parser)
    }
    
    public static func shareWithViewController(
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
    
    static func graphLoaderWithPath(graphPath: String, accessToken: FBSDKAccessToken) -> AsyncTypes<NSDictionary, NSError>.Async
    {
        return graphLoaderWithPath(graphPath, parameters:nil, accessToken:accessToken)
    }
    
    public static func graphLoaderWithPath(
        graphPath: String, parameters: [String:AnyObject]?, accessToken: FBSDKAccessToken) -> AsyncTypes<NSDictionary, NSError>.Async
    {
        return graphLoaderWithPath(graphPath, httpMethod: "GET", parameters:parameters, accessToken:accessToken)
    }
    
    static func graphLoaderWithPath(
        graphPath  : String,
        httpMethod : String,
        parameters : [String:AnyObject]?,
        accessToken: FBSDKAccessToken) -> AsyncTypes<NSDictionary, NSError>.Async
    {
        let result = graphPath.stringByReplacingOccurrencesOfString(" ", withString:"+")
        let graphLoader = jffGenericFacebookGraphRequestLoader(accessToken: accessToken, graphPath: result, httpMethod: httpMethod, parameters: parameters)
        
        return graphLoader
    }
    
//    static func postImage(image: UIImage, message: String?) -> AsyncTypes<NSDictionary>.Async
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

    private static func userParser() -> AsyncTypes2<NSDictionary, SocialFacebookUser, NSError>.AsyncBinder
    {
        let parser = { (result: NSDictionary) -> AsyncTypes<SocialFacebookUser, NSError>.Async in
            
            let result = SocialFacebookUser.createSocialFacebookUserWithJsonObject(result)
            return async(result: result)
        }
        
        return parser
    }
    
//    private static func usersParser() -> AsyncTypes2<NSDictionary, [SocialFacebookUser]>.AsyncBinder {
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
    
//    public static func friendsLoaderWithFields(fields: [String], uid: String = "me") -> AsyncTypes<[SocialFacebookUser]>.Async {
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
