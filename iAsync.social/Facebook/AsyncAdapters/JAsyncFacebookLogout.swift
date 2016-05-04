//
//  JAsyncFacebookLogout.swift
//  iAsync_social
//
//  Created by Vladimir Gorbenko on 09.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import FBSDKCoreKit
import FBSDKLoginKit

final private class JAsyncFacebookLogout : AsyncInterface {

    private var finishCallback: AsyncTypes<ValueT, ErrorT>.DidFinishAsyncCallback?
    private var timer: Timer?

    private let renewSystemAuthorization: Bool

    typealias ErrorT = NSError
    typealias ValueT = ()

    init(renewSystemAuthorization: Bool) {
        self.renewSystemAuthorization = renewSystemAuthorization
    }

    var isForeignThreadResultCallback: Bool {
        return true
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
        finishCallback  : AsyncTypes<ValueT, ErrorT>.DidFinishAsyncCallback,
        stateCallback   : AsyncChangeStateCallback,
        progressCallback: AsyncProgressCallback)
    {
        self.finishCallback = finishCallback

        let manager  = FBSDKLoginManager()
        self.manager = manager

        if renewSystemAuthorization {

            FBSDKLoginManager.renewSystemCredentials({ (result: ACAccountCredentialRenewResult, error: NSError!) -> Void in
                self.logOut()
            })
            return
        }

        logOut()
    }

    func doTask(task: AsyncHandlerTask) {
        assert(task.unsubscribedOrCanceled)
    }

    func notifyFinished() {
        finishCallback?(result: .Success(()))
    }
}

func facebookLogout(renewSystemAuthorization: Bool) -> AsyncTypes<(), NSError>.Async
{
    let factory = { () -> JAsyncFacebookLogout in

        let object = JAsyncFacebookLogout(renewSystemAuthorization: renewSystemAuthorization)
        return object
    }

    return AsyncBuilder.buildWithAdapterFactory(factory)
}
