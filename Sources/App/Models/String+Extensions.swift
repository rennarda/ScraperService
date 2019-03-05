//
//  String+Extensions.swift
//  SwimTimeScraper
//
//  Created by Andrew Rennard - Lines of Business North and Nations on 04/03/2019.
//  Copyright © 2019 Taptix. All rights reserved.
//

import Foundation
extension String {

    var timeValue: TimeInterval {
        var seconds:Double = 0
        if let colonLocation = self.range(of: ":")?.lowerBound,
           let minutes = Int(self[..<colonLocation]),
           let remainingSeconds = Double(self.suffix(from: self.index(after: colonLocation)))
        {
            seconds = 60 * Double(minutes)
            seconds += remainingSeconds
        }
        else if let secondsFromString = Double(self){
            seconds = secondsFromString
        }
        return seconds
    }
}
