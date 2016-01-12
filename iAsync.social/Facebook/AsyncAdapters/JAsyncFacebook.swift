//
//  JAsyncFacebook.swift
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

final private class JFacebookGeneralRequestLoader : AsyncInterface {

    private var requestConnection: FBSDKGraphRequestConnection?
    
    private let accessToken: FBSDKAccessToken
    private let graphPath  : String
    private let httpMethod : String?
    private let parameters : [String:AnyObject]?
    
    init(
        accessToken: FBSDKAccessToken,
        graphPath  : String,
        httpMethod : String?,
        parameters : [String:AnyObject]?)
    {
        self.accessToken = accessToken
        self.graphPath   = graphPath
        self.httpMethod  = httpMethod
        self.parameters  = parameters
    }
    
    typealias ErrorT = NSError
    typealias ValueT = NSDictionary
    
    var isForeignThreadResultCallback: Bool {
        return false
    }
    
    func asyncWithResultCallback(
        finishCallback  : AsyncTypes<ValueT, ErrorT>.DidFinishAsyncCallback,
        stateCallback   : AsyncChangeStateCallback,
        progressCallback: AsyncProgressCallback)
    {
        let fbRequest = FBSDKGraphRequest(
            graphPath  : graphPath ,
            parameters : parameters,
            tokenString: accessToken.tokenString,
            version    : nil,
            HTTPMethod : httpMethod)
        
        requestConnection = fbRequest.startWithCompletionHandler { (
            connection : FBSDKGraphRequestConnection!,
            graphObject: AnyObject!,
            error      : NSError!) -> Void in
            
            if let graphObject = graphObject as? NSDictionary {
                
                finishCallback(result: .Success(graphObject))
            } else {
                
                finishCallback(result: .Failure(JFacebookError(nativeError: error)))
            }
        }
    }
    
    func doTask(task: AsyncHandlerTask)
    {
        assert(task.unsubscribedOrCanceled)
        if task == .Cancel {
            
            if let requestConnection = requestConnection {
                self.requestConnection = nil
                requestConnection.cancel()
            }
        }
    }
}

func jffGenericFacebookGraphRequestLoader(
    accessToken accessToken: FBSDKAccessToken,
    graphPath  : String,
    httpMethod : String?,
    parameters : [String:AnyObject]?) -> AsyncTypes<NSDictionary, NSError>.Async
{
    let factory = { () -> JFacebookGeneralRequestLoader in

        let object = JFacebookGeneralRequestLoader(
            accessToken: accessToken,
            graphPath  : graphPath  ,
            httpMethod : httpMethod ,
            parameters : parameters
        )
        return object
    }
    
    return AsyncBuilder.buildWithAdapterFactory(factory)
}

func jffFacebookGraphRequestLoader(accessToken: FBSDKAccessToken, graphPath: String) -> AsyncTypes<NSDictionary, NSError>.Async
{
    return jffGenericFacebookGraphRequestLoader(accessToken: accessToken, graphPath: graphPath, httpMethod: nil, parameters: nil)
}
