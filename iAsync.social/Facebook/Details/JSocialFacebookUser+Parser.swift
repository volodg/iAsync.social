//
//  JSocialFacebookUser+Parser.swift
//  JSocial
//
//  Created by Vladimir Gorbenko on 09.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_utils
//import JJsonTools

public extension JSocialFacebookUser {

    class func createSocialFacebookUserWithJsonObject(json: AnyObject) -> Result<JSocialFacebookUser>
    {
        return Result.error(JError(description: "TODO implement"))
//        let facebookID = json.string("id")
//        let email      = json.optionString("email"   )
//        let name       = json.optionString("name"    )
//        let gender     = json.optionString("gender"  )
//        let biography  = json.optionString("bio"     )
//        let birthday   = json.optionString("birthday")
//        
//        let url = json.optionString("picture" </> "data" </> "url")
//        
//        return (facebookID, email, name, gender, biography, birthday, url) >>= {
//            (facebookID, email, name, gender, biography, birthdayStr, url) -> Result<JSocialFacebookUser> in
//            
//            let birthday: NSDate?
//                
//            if let birthdayStr = birthdayStr {
//                
//                let formatter = NSDateFormatter()
//                
//                formatter.dateFormat = "MM/dd/yyyy"
//                formatter.locale   = NSLocale(localeIdentifier: "en_US")
//                formatter.timeZone = NSTimeZone(name: "GMT")
//                
//                birthday = formatter.dateFromString(birthdayStr)
//            } else {
//                birthday = nil
//            }
//            
//            //TODO isMale = gender == "male"
//            let photoURL: NSURL?
//            if let url = url {
//                photoURL = NSURL(string: url)
//            } else {
//                photoURL = nil
//            }
//            
//            let result = JSocialFacebookUser(
//                facebookID: facebookID,
//                email     : email     ,
//                name      : name      ,
//                gender    : gender    ,
//                birthday  : birthday  ,
//                biography : biography ,
//                photoURL  : photoURL
//            )
//            return Result.value(result)
//        }
    }
}
