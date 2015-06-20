//
//  JAsyncFacebookLogout.swift
//  iAsync_social
//
//  Created by Vladimir Gorbenko on 09.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import FBSDKCoreKit
import FBSDKLoginKit

import Result

private class JAsyncFacebookLogout : JAsyncInterface {
    
    private var finishCallback: JAsyncTypes<ResultType>.JDidFinishAsyncCallback?
    private var timer: Timer?
    
    private let renewSystemAuthorization: Bool
    
    typealias ResultType = ()
    
    init(renewSystemAuthorization: Bool) {
        
        self.renewSystemAuthorization = renewSystemAuthorization
    }
    
    var isForeignThreadResultCallback: Bool {
        return false
    }
    
    func logOut() {
        
        manager?.logOut()
        
        let timer = Timer()
        self.timer = timer
        
        //TODO remove ????
        let _ = timer.addBlock( { [weak self] (cancel: () -> ()) -> () in
            
            cancel()
            self?.notifyFinished()
        }, duration: 1.0)
    }
    
    var manager: FBSDKLoginManager?
    
    func asyncWithResultCallback(
        finishCallback: JAsyncTypes<ResultType>.JDidFinishAsyncCallback,
        stateCallback: JAsyncChangeStateCallback,
        progressCallback: JAsyncProgressCallback)
    {
        self.finishCallback = finishCallback
        
        let manager = FBSDKLoginManager()
        self.manager = manager
        
        if renewSystemAuthorization {
            
            FBSDKLoginManager.renewSystemCredentials({ (result: ACAccountCredentialRenewResult, error: NSError!) -> Void in
                
                self.logOut()
            })
            return
        }
        
        logOut()
    }
    
    func doTask(task: JAsyncHandlerTask)
    {
        assert(task.rawValue <= JAsyncHandlerTask.Cancel.rawValue)
    }
    
    func notifyFinished()
    {
        finishCallback?(result: Result.success(()))
    }
}

func jffFacebookLogout(renewSystemAuthorization: Bool) -> JAsyncTypes<()>.JAsync
{
    let factory = { () -> JAsyncFacebookLogout in
        
        let object = JAsyncFacebookLogout(renewSystemAuthorization: renewSystemAuthorization)
        return object
    }
    
    return JAsyncBuilder.buildWithAdapterFactory(factory)
}
