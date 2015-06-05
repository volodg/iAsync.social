//
//  JAsyncFacebookLogin.swift
//  JSocial
//
//  Created by Vladimir Gorbenko on 08.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import FBSDKCoreKit
import FBSDKLoginKit

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
        finishCallback: JAsyncTypes<ResultType>.JDidFinishAsyncCallback,
        stateCallback: JAsyncChangeStateCallback,
        progressCallback: JAsyncProgressCallback)
    {
        let currPermissions: Set<String>
        
        if let token = FBSDKAccessToken.currentAccessToken() {
            currPermissions = token.permissions as? Set<String> ?? Set([])
            
            if permissions.isSubsetOf(currPermissions) {
                finishCallback(result: Result.value(token))
                return
            }
        } else {
            currPermissions = Set([])
        }
        
        var requestPermissions = permissions
        requestPermissions.unionInPlace(currPermissions)
        
        //exclude publich pemissions
        requestPermissions.subtractInPlace(["publish_actions", "publish_stream", "publish_checkins"])
        
        let loginManager = FBSDKLoginManager()
        
        loginManager.logInWithReadPermissions(
            Array(requestPermissions),
            handler: { [weak self] (result: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
            
            if let error = error {
                
                finishCallback(result: Result.error(error))
            } else if let token = result.token {
                
                //TODO wrap error
                finishCallback(result: Result.value(token))
            } else if result.isCancelled {
                
                finishCallback(result: Result.error(JAsyncFinishedByCancellationError()))
            } else {
                
                finishCallback(result: Result.error(Error(description: "unsupported fb error, TODO fix")))
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
