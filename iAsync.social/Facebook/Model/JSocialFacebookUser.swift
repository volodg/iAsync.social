//
//  SocialFacebookUser.swift
//  JSocial
//
//  Created by Vladimir Gorbenko on 07.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

//Image urls docs
// http://developers.facebook.com/docs/reference/api/using-pictures/

public let fbUserBithdayDateFormat = createUserBithdayDateFormat()

private func createUserBithdayDateFormat() -> NSDateFormatter {
    
    let result = NSDateFormatter()
    
    result.dateFormat = "MM/dd/yyyy"
    result.locale   = NSLocale(localeIdentifier: "en_US")
    result.timeZone = NSTimeZone(name: "GMT")
    
    return result
}

public struct SocialFacebookUser {
    
    public let id        : String
    public let email     : String?
    public let name      : String?
    public let gender    : String?
    public let birthday  : NSDate?
    public let biography : String?
}

extension SocialFacebookUser : Equatable {}

public func ==(lhs: SocialFacebookUser, rhs: SocialFacebookUser) -> Bool {
    
    let result = lhs.id         == rhs.id
              && lhs.email      == rhs.email
              && lhs.name       == rhs.name
              && lhs.gender     == rhs.gender
              && lhs.birthday   == rhs.birthday
              && lhs.biography  == rhs.biography
    return result
}
