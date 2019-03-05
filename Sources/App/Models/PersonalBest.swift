//
//  PersonalBest.swift
//  SwimTimeScraper
//
//  Created by Andrew Rennard - Lines of Business North and Nations on 22/02/2019.
//  Copyright © 2019 Taptix. All rights reserved.
//

import Foundation

struct PersonalBest: Codable, CustomStringConvertible, Equatable {
    enum Course: String, Codable {
        case short = "Short"
        case long = "Long"
    }
    
    let name:String
    let time:String
    let timeInterval:TimeInterval
    let finaPoints:String
    let dateAttained:Date
    let meet:String
    let venue:String
    let licence:String
    let level:String
    let course:Course

    var description: String {
        return """
        Event:  \(name) \(course)
        Time:   \(time)
        Points: \(finaPoints)
        Meet:   \(dateAttained) at \(meet), \(venue) (level \(level))
        
        """
    }
    
    func setInLastMonth(_ date : Date = Date()) -> Bool {
        return setSince(monthsAgo: -1, date: date)
    }

    func setInLast3Months(_ date : Date = Date()) -> Bool {
        return setSince(monthsAgo: -3, date: date)
    }

    func setInLast6Months(_ date : Date = Date()) -> Bool {
        return setSince(monthsAgo: -6, date: date)
    }

    func setInLast12Months(_ date : Date = Date()) -> Bool {
        return setSince(monthsAgo: -12, date: date)
    }
    
    private func setSince(monthsAgo:Int, date : Date = Date()) -> Bool {
        let components = DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: monthsAgo, day: nil, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        
        if let sinceDate = Calendar.current.date(byAdding: components, to: date) {
            return sinceDate <= dateAttained
        }
        else {
            return false
        }
    }

    
}
