//
//  JAsyncFacebookLogin.swift
//  iAsync_social
//
//  Created by Vladimir Gorbenko on 08.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import FBSDKCoreKit
import FBSDKLoginKit

import Result

private class JAsyncFacebookLogin : JAsyncInterface {

    private let permissions: Set<String>
    
    init(permissions: Set<String>)
    {
        self.permissions = permissions
    }
    
    typealias ResultType = FBSDKAccessToken
    
    var isForeignThreadResultCallback: Bool {
        return false
    }
    
    func asyncWithResultCallback(
        finishCallback  : JAsyncTypes<ResultType>.JDidFinishAsyncCallback,
        stateCallback   : JAsyncChangeStateCallback,
        progressCallback: JAsyncProgressCallback)
    {
        let currPermissions: Set<String>
        
        if let token = FBSDKAccessToken.currentAccessToken() {
            currPermissions = token.permissions as? Set<String> ?? Set([])
            
            if permissions.isSubsetOf(currPermissions) {
                finishCallback(result: Result.success(token))
                return
            }
        } else {
            currPermissions = Set([])
        }
        
        var requestPermissions = permissions
        requestPermissions.unionInPlace(currPermissions)
        requestPermissions.subtractInPlace(["contact_email"])
        
        //exclude publich pemissions
        //"user_posts",
        let publishPermissions = ["publish_actions", "publish_stream", "publish_checkins", "manage_pages"]
        
        let requestPublishPermissions = requestPermissions.intersect(publishPermissions)
        let needsPublish = requestPublishPermissions.count != 0
        
        requestPermissions.subtractInPlace(publishPermissions)
        
        if let token = FBSDKAccessToken.currentAccessToken()
        {
            let currPermissions = token.permissions as? Set<String> ?? Set([])
            
            if requestPermissions.isSubsetOf(currPermissions)
            {
                let loginManager = FBSDKLoginManager()
                
                loginManager.logInWithPublishPermissions(
                    Array(requestPublishPermissions),
                    handler: { [weak self] (result: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
                        
                        if let error = error {
                            
                            finishCallback(result: Result.failure(error))
                        } else if let token = result.token {
                            
                            finishCallback(result: Result.success(token))
                        } else if result.isCancelled {
                            
                            finishCallback(result: Result.failure(JAsyncFinishedByCancellationError()))
                        } else {
                            
                            finishCallback(result: Result.failure(Error(description: "unsupported fb error, TODO fix")))
                        }
                    })
                
                return
            }
        }
        
        let loginManager = FBSDKLoginManager()
        
        //TODO check if needs login here !!!!
        //loginManager.logInWithPublishPermissions(nil, handler: nil)
        
        loginManager.logInWithReadPermissions(
            Array(requestPermissions),
            handler: { [weak self] (result: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
            
            if let error = error {
                
                //TODO wrap error
                finishCallback(result: Result.failure(error))
            } else if let token = result.token {
                
                if needsPublish {
                    
                    loginManager.logInWithPublishPermissions(
                        Array(requestPublishPermissions),
                        handler: { [weak self] (result: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
                            
                            if let error = error {
                                
                                finishCallback(result: Result.failure(error))
                            } else if let token = result.token {
                                
                                finishCallback(result: Result.success(token))
                            } else if result.isCancelled {
                                
                                finishCallback(result: Result.failure(JAsyncFinishedByCancellationError()))
                            } else {
                                
                                //TODO wrap error
                                finishCallback(result: Result.failure(Error(description: "unsupported fb error, TODO fix")))
                            }
                        })
                } else {
                
                    finishCallback(result: Result.success(token))
                }
            } else if result.isCancelled {
                
                finishCallback(result: Result.failure(JAsyncFinishedByCancellationError()))
            } else {
                
                //TODO wrap error
                finishCallback(result: Result.failure(Error(description: "unsupported fb error, TODO fix")))
            }
        })
    }
    
    func doTask(task: JAsyncHandlerTask)
    {
        assert(task.rawValue <= JAsyncHandlerTask.Cancel.rawValue)
    }
}

func jffFacebookLogin(permissions: Set<String>) -> JAsyncTypes<FBSDKAccessToken>.JAsync
{
    let factory = { () -> JAsyncFacebookLogin in
        
        let object = JAsyncFacebookLogin(permissions: permissions)
        return object
    }
    
    return JAsyncBuilder.buildWithAdapterFactory(factory)
}
