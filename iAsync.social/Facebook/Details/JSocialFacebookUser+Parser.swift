//
//  JSocialFacebookUser+Parser.swift
//  JSocial
//
//  Created by Vladimir Gorbenko on 09.10.14.
//  Copyright (c) 2014 EmbeddedSources. All rights reserved.
//

import Foundation

import iAsync_utils

import Argo
import Runes

private struct SocialFacebookUserStruct {
    
    let id        : String
    let email     : String?
    let name      : String?
    let firstName : String?
    let lastName  : String?
    let gender    : String?
    let birthday  : String?
    let biography : String?
}

extension SocialFacebookUserStruct : Decodable {
    
    static func create
        (id        : String )
        (email     : String?)
        (name      : String?)
        (firstName : String?)
        (lastName  : String?)
        (gender    : String?)
        (birthday  : String?)
        (biography : String?) -> SocialFacebookUserStruct
    {
        return self(id: id, email: email, name: name, firstName: firstName, lastName: lastName, gender: gender, birthday: birthday, biography: biography)
    }
    
    static func decode(j: JSON) -> Decoded<SocialFacebookUserStruct>
    {
        return self.create
            <^> j <| "id"
            <*> j <|? "email"
            <*> j <|? "name"
            <*> j <|? "first_name"
            <*> j <|? "last_name"
            <*> j <|? "gender"
            <*> j <|? "birthday"
            <*> j <|? "bio"
    }
}

extension SocialFacebookUser {
    
    static func createSocialFacebookUserWithJsonObject(json: AnyObject) -> Result<SocialFacebookUser>
    {
        println("json: \(json)")
        let data: Decoded<SocialFacebookUserStruct> = decode(json)
        
        switch data {
        case let .Success(v):
            
            let birthday: NSDate?
            
            if let date = v.value.birthday {
                
                birthday = fbUserBithdayDateFormat.dateFromString(date)
            } else {
                
                birthday = nil
            }
            
            let result = SocialFacebookUser(
                id        : v.value.id,
                email     : v.value.email,
                name      : v.value.name,
                firstName : v.value.firstName,
                lastName  : v.value.lastName,
                gender    : v.value.gender,
                birthday  : birthday,
                biography : v.value.biography)
            
            return Result.value(result)
        case let .TypeMismatch(str):
            return Result.error(Error(description: "parse fasebook user TypeMismatch: \(str) json: \(json)"))
        case let .MissingKey(str):
            return Result.error(Error(description: "parse fasebook user MissingKey: \(str) json: \(json)"))
        }
    }
}
