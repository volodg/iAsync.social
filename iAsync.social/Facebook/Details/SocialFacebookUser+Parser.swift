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
import Curry

//  "updated_time" : "2014-09-13T08:38:51+0000",
//  "verified": true }

private struct SocialFacebookUserStruct1 {
    
    let id         : String
    let email      : String?
    let name       : String?
    let firstName  : String?
    let lastName   : String?
    let gender     : String?
}

private struct SocialFacebookUserStruct2 {
    
    let biography  : String?
    let link       : String?
    let locale     : String?
    let timezone   : Int?
    let updatedTime: String?
    let verified   : Bool?
}

private struct SocialFacebookUserStruct3 {
    
    let birthday   : String?
}

extension SocialFacebookUserStruct1 : Decodable
{
    static func decode(j: JSON) -> Decoded<SocialFacebookUserStruct1>
    {
        return curry(self.init)
            <^> j <|  "id"
            <*> j <|? "email"
            <*> j <|? "name"
            <*> j <|? "first_name"
            <*> j <|? "last_name"
            <*> j <|? "gender"
    }
}

extension SocialFacebookUserStruct2 : Decodable
{
    static func decode(j: JSON) -> Decoded<SocialFacebookUserStruct2>
    {
        return curry(self.init)
            <^> j <|? "bio"
            <*> j <|? "link"
            <*> j <|? "locale"
            <*> j <|? "timezone"
            <*> j <|? "updated_time"
            <*> j <|? "verified"
    }
}

extension SocialFacebookUserStruct3 : Decodable
{
    static func decode(j: JSON) -> Decoded<SocialFacebookUserStruct3>
    {
        return curry(self.init)
            <^> j <|? "birthday"
    }
}

extension SocialFacebookUser {
    
    static func createSocialFacebookUserWithJsonObject(json: AnyObject) -> AsyncResult<SocialFacebookUser, NSError>
    {
        let struct1: Decoded<SocialFacebookUserStruct1> = decode(json)
        
        let structs = struct1 >>- { res1 -> Decoded<(SocialFacebookUserStruct1, SocialFacebookUserStruct2, SocialFacebookUserStruct3)> in
            
            let res2: Decoded<SocialFacebookUserStruct2> = decode(json)
            
            return res2 >>- { res2 -> Decoded<(SocialFacebookUserStruct1, SocialFacebookUserStruct2, SocialFacebookUserStruct3)> in
                
                let res3: Decoded<SocialFacebookUserStruct3> = decode(json)
                
                return res3.map( { (res1, res2, $0) } )
            }
        }
        
        switch structs {
        case .Success(let v):
            
            let birthday: NSDate?
            
            if let date = v.2.birthday {
                
                birthday = createFbUserBithdayDateFormat().dateFromString(date)
            } else {
                
                birthday = nil
            }
            
            let result = SocialFacebookUser(
                id         : v.0.id         ,
                email      : v.0.email      ,
                name       : v.0.name       ,
                firstName  : v.0.firstName  ,
                lastName   : v.0.lastName   ,
                gender     : v.0.gender     ,
                birthday   : birthday       ,
                biography  : v.1.biography  ,
                link       : v.1.link       ,
                locale     : v.1.locale     ,
                timezone   : v.1.timezone   ,
                updatedTime: v.1.updatedTime,
                verified   : v.1.verified
            )
            
            return .Success(result)
        case .Failure(let error):
            switch error {
            case .TypeMismatch(let expected, let actual):
                return .Failure(Error(description: "parse fasebook user TypeMismatch expected: \(expected) actual: \(actual)"))
            case .MissingKey(let str):
                return .Failure(Error(description: "parse fasebook user MissingKey: \(str) json: \(json)"))
            case .Custom(let str):
                return .Failure(Error(description: "parse fasebook user Custom: \(str) json: \(json)"))
            }
        }
    }
}
