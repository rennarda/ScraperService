//
//  Swimmer.swift
//  SwimTimeScraper
//
//  Created by Andrew Rennard - Lines of Business North and Nations on 25/02/2019.
//  Copyright © 2019 Taptix. All rights reserved.
//

import Foundation

struct Swimmer: Codable, Equatable {
    static func == (lhs: Swimmer, rhs: Swimmer) -> Bool {
        return lhs.name == rhs.name && lhs.id == rhs.id && lhs.pbs == rhs.pbs
    }
    
    let name:String
    let id:Int
    var allTimePbs:[PersonalBest]
    var last12MonthPbs:[PersonalBest]?
    
    var pbs:[PersonalBest] {
        return allTimePbs
    }
}
