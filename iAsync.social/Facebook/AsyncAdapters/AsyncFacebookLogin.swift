//
//  AsyncFacebookLogin.swift
//  iAsync_social
//
//  Created by Vladimir Gorbenko on 08.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import FBSDKCoreKit
import FBSDKLoginKit

final private class AsyncFacebookLogin : AsyncInterface {

    private let permissions: Set<String>
    private let rootVC: UIViewController
    
    init(permissions: Set<String>, rootVC: UIViewController)
    {
        self.rootVC      = rootVC
        self.permissions = permissions
    }
    
    typealias ErrorT = NSError
    typealias ValueT = FBSDKAccessToken
    
    var isForeignThreadResultCallback: Bool {
        return false
    }
    
    func asyncWithResultCallback(
        finishCallback  : AsyncTypes<ValueT, ErrorT>.DidFinishAsyncCallback,
        stateCallback   : AsyncChangeStateCallback,
        progressCallback: AsyncProgressCallback)
    {
        let currPermissions: Set<String>
        
        if let token = FBSDKAccessToken.currentAccessToken() {
            currPermissions = token.permissions as? Set<String> ?? Set([])
            
            if permissions.isSubsetOf(currPermissions) {
                finishCallback(result: .Success(token))
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
        
        if let token = FBSDKAccessToken.currentAccessToken() {
            
            let currPermissions = token.permissions as? Set<String> ?? Set([])
            
            if requestPermissions.isSubsetOf(currPermissions) {
                self.requestPublishPermissions(requestPublishPermissions, finishCallback: finishCallback)
                return
            }
        }
        
        let loginManager = FBSDKLoginManager()
        
        loginManager.logInWithReadPermissions(
            Array(requestPermissions),
            fromViewController: rootVC,
            handler: { [weak self] (result: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
            
            if let self_ = self {
                
                if let error = error {
                    
                    //TODO wrap error
                    finishCallback(result: .Failure(error))
                } else if let token = result.token {
                    
                    if needsPublish {
                        
                        let timer = Timer()
                        self_.timer = timer
                        let _ = timer.addBlock({ (cancel) -> Void in
                            cancel()
                            self?.requestPublishPermissions(requestPublishPermissions, finishCallback: finishCallback)
                        }, duration: 0.3)
                    } else {
                    
                        finishCallback(result: .Success(token))
                    }
                } else if result.isCancelled {
                    
                    finishCallback(result: .Interrupted)
                } else {
                    
                    //TODO wrap error
                    finishCallback(result: .Failure(Error(description: "unsupported fb error, TODO fix")))
                }
            } else {
                
                finishCallback(result: .Interrupted)
            }
        })
    }
    
    var timer: Timer?
    
    private func requestPublishPermissions(
        requestPublishPermissions: Set<String>,
        finishCallback: AsyncTypes<ValueT, ErrorT>.DidFinishAsyncCallback)
    {
        let loginManager = FBSDKLoginManager()
        
        loginManager.logInWithPublishPermissions(
            Array(requestPublishPermissions),
            fromViewController: self.rootVC,
            handler: { (result: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
                
                if let error = error {
                    
                    finishCallback(result: .Failure(error))
                } else if let token = result.token {
                    
                    finishCallback(result: .Success(token))
                } else if result.isCancelled {
                    
                    finishCallback(result: .Interrupted)
                } else {
                    
                    //TODO wrap error
                    finishCallback(result: .Failure(Error(description: "unsupported fb error, TODO fix")))
                }
        })
    }
    
    func doTask(task: AsyncHandlerTask)
    {
        assert(task.unsubscribedOrCanceled)
    }
}

final class FBApi {

    static func loginLoader(permissions: Set<String>, rootVC: UIViewController) -> AsyncTypes<FBSDKAccessToken, NSError>.Async
    {
        let factory = { () -> AsyncFacebookLogin in
            
            let object = AsyncFacebookLogin(permissions: permissions, rootVC: rootVC)
            return object
        }
        
        return AsyncBuilder.buildWithAdapterFactory(factory)
    }
}
