//
//  SocialFacebookUser+Parser.swift.swift
//  iAsync_social
//
//  Created by Vladimir Gorbenko on 09.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_utils

import Argo
import Runes

//  "updated_time" : "2014-09-13T08:38:51+0000",
//  "verified": true }

private struct SocialFacebookUserStruct1 {
    
    let id         : String
    let email      : String?
    let name       : String?
    let firstName  : String?
    let lastName   : String?
    let gender     : String?
    let birthday   : String?
}

private struct SocialFacebookUserStruct2 {
    
    let biography  : String?
    let link       : String?
    let locale     : String?
    let timezone   : Int?
    let updatedTime: String?
    let verified   : Bool?
}

extension SocialFacebookUserStruct1 : Decodable {
    
    static func create
        (id         : String )
        (email      : String?)
        (name       : String?)
        (firstName  : String?)
        (lastName   : String?)
        (gender     : String?)
        (birthday   : String?)
        -> SocialFacebookUserStruct1
    {
        return self(
            id         : id         ,
            email      : email      ,
            name       : name       ,
            firstName  : firstName  ,
            lastName   : lastName   ,
            gender     : gender     ,
            birthday   : birthday
        )
    }
    
    static func decode(j: JSON) -> Decoded<SocialFacebookUserStruct1>
    {
        return self.create
            <^> j <| "id"
            <*> j <|? "email"
            <*> j <|? "name"
            <*> j <|? "first_name"
            <*> j <|? "last_name"
            <*> j <|? "gender"
            <*> j <|? "birthday"
    }
}

extension SocialFacebookUserStruct2 : Decodable {
    
    static func create
        (biography  : String?)
        (link       : String?)
        (locale     : String?)
        (timezone   : Int?)
        (updatedTime: String?)
        (verified   : Bool?)
        -> SocialFacebookUserStruct2
    {
        return self(
            biography  : biography  ,
            link       : link       ,
            locale     : locale     ,
            timezone   : timezone   ,
            updatedTime: updatedTime,
            verified   : verified)
    }
    
    static func decode(j: JSON) -> Decoded<SocialFacebookUserStruct2>
    {
        return self.create
            <^> j <|? "bio"
            <*> j <|? "link"
            <*> j <|? "locale"
            <*> j <|? "timezone"
            <*> j <|? "updated_time"
            <*> j <|? "verified"
    }
}

extension SocialFacebookUser {
    
    static func createSocialFacebookUserWithJsonObject(json: AnyObject) -> AsyncResult<SocialFacebookUser, NSError>
    {
        let struct1: Decoded<SocialFacebookUserStruct1> = decode(json)
        
        let structs = struct1 >>- { res1 -> Decoded<(SocialFacebookUserStruct1, SocialFacebookUserStruct2)> in
            
            let res2: Decoded<SocialFacebookUserStruct2> = decode(json)
            return res2.map { (res1, $0) }
        }
        
        switch structs {
        case .Success(let v):
            
            let birthday: NSDate?
            
            if let date = v.value.0.birthday {
                
                birthday = createFbUserBithdayDateFormat().dateFromString(date)
            } else {
                
                birthday = nil
            }
            
            let result = SocialFacebookUser(
                id         : v.value.0.id         ,
                email      : v.value.0.email      ,
                name       : v.value.0.name       ,
                firstName  : v.value.0.firstName  ,
                lastName   : v.value.0.lastName   ,
                gender     : v.value.0.gender     ,
                birthday   : birthday             ,
                biography  : v.value.1.biography  ,
                link       : v.value.1.link       ,
                locale     : v.value.1.locale     ,
                timezone   : v.value.1.timezone   ,
                updatedTime: v.value.1.updatedTime,
                verified   : v.value.1.verified
            )
            
            return AsyncResult.success(result)
        case .TypeMismatch(let str):
            return AsyncResult.failure(Error(description: "parse fasebook user TypeMismatch: \(str) json: \(json)"))
        case .MissingKey(let str):
            return AsyncResult.failure(Error(description: "parse fasebook user MissingKey: \(str) json: \(json)"))
        }
    }
}
