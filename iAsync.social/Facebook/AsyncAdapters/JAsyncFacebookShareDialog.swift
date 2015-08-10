//
//  JAsyncFacebookDialog.swift
//  iAsync_social
//
//  Created by Vladimir Gorbenko on 09.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_async
import iAsync_utils

import FBSDKShareKit

@objc public class JAsyncFacebookShareDialog: NSObject, JAsyncInterface, FBSDKSharingDelegate {
    
    private let viewController: UIViewController
    private let contentURL    : NSURL
    private let usersIDs      : [String]
    private let title         : String
    
    init(
        viewController: UIViewController,
        contentURL    : NSURL,
        usersIDs      : [String],
        title         : String)
    {
        self.viewController = viewController
        self.contentURL     = contentURL
        self.usersIDs       = usersIDs
        self.title          = title
    }
    
    public typealias ErrorT = NSError
    public typealias ValueT = Void
    
    private var shareDialog: FBSDKShareDialog? = nil
    
    private var finishCallback: AsyncTypes<ValueT, ErrorT>.JDidFinishAsyncCallback?
    
    public func asyncWithResultCallback(
        finishCallback  : AsyncTypes<ValueT, ErrorT>.JDidFinishAsyncCallback,
        stateCallback   : AsyncChangeStateCallback,
        progressCallback: AsyncProgressCallback)
    {
        self.finishCallback = finishCallback
        
        let content = FBSDKShareLinkContent()
        
        content.peopleIDs    = usersIDs
        content.contentURL   = contentURL
        content.contentTitle = title
        
        shareDialog = FBSDKShareDialog.showFromViewController(
            viewController,
            withContent: content,
            delegate   : self)
    }
    
    public func doTask(task: JAsyncHandlerTask)
    {
        assert(task.unsubscribedOrCanceled)
    }
    
    public var isForeignThreadResultCallback: Bool {
        return false
    }
    
    @objc public func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!)
    {
        finishCallback?(result: AsyncResult.success(()))
    }
    
    public func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!)
    {
        finishCallback?(result: AsyncResult.failure(error))
    }
    
    public func sharerDidCancel(sharer: FBSDKSharing!)
    {
        finishCallback?(result: .Interrupted)
    }
}

func jffShareFacebookDialog(
    viewController viewController: UIViewController,
    contentURL    : NSURL,
    usersIDs      : [String],
    title         : String) -> AsyncTypes<(), NSError>.Async
{
    let factory = { () -> JAsyncFacebookShareDialog in
        
        return JAsyncFacebookShareDialog(
            viewController: viewController,
            contentURL    : contentURL    ,
            usersIDs      : usersIDs      ,
            title         : title)
    }
    
    return JAsyncBuilder.buildWithAdapterFactory(factory)
}
