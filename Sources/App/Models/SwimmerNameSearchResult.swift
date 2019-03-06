//
//  SwimmerNameSearchResult.swift
//  SwimTimeScraper
//
//  Created by Andy Rennard on 01/03/2019.
//  Copyright © 2019 Taptix. All rights reserved.
//

import Foundation

struct SwimmerNameSearchResult: Codable {
    enum Gender:String, Codable {
        case female = "Female"
        case male = "Male"
    }

    let id:Int
    let familyName:String
    let givenName:String
    let knownAsName:String
    let yearOfBirth:String
    let gender:Gender
    let club:String
}

