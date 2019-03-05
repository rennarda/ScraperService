//
//  Scraper.swift
//  SwimTimeScraper
//
//  Created by Andrew Rennard - Lines of Business North and Nations on 22/02/2019.
//  Copyright © 2019 Taptix. All rights reserved.
//

import Foundation
import Kanna

struct Scraper {
    
    public enum ScraperError: Error {
        case urlFormatError
        case serverError
        case notFoundError
    }
    
    private enum Endpoints: String {
        case allTimePbs = "https://www.swimmingresults.org/individualbest/personal_best.php?mode=A&tiref="
        case last12MonthPbs = "https://www.swimmingresults.org/individualbest/personal_best.php?mode=L&tiref="

        func urlFor(swimmerID:Int) -> URL {
            return URL(string:self.rawValue + "\(swimmerID)")!
        }
        
        func urlFor(swimmerName:String) throws -> URL {
            let urlString = self.rawValue + swimmerName
            guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed),
                  let url = URL(string:escapedString)
            else {
                throw ScraperError.urlFormatError
            }
            return url
        }
    }
    
    private func newSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        if #available(OSX 10.13, *, iOS 11.0, *) {
            configuration.waitsForConnectivity = false
        } else {
        }
        configuration.timeoutIntervalForRequest = 5
        let session = URLSession.init(configuration: configuration)
        return session
        
    }
    
    /// Fetch the personal bests for the given swimmer
    ///
    /// - Parameters:
    ///   - id: the swimmer ID
    ///   - completion: returns the swimmer name, all time PBs and last 12 month PBs
    func getPersonalBests(id:Int, completion: @escaping (String?, [PersonalBest]?, [PersonalBest]?, Error?) -> Void ){
        getAllTimePersonalBests(id: id) { (name, allTimePBs, error) in
            guard error == nil else {
                completion(nil, nil, nil, error)
                return
            }
            self.getLast12MonthPersonalBests(id: id, completion: { (name, last12MonthPbs, error) in
                guard error == nil else {
                    completion(nil, nil, nil, error)
                    return
                }
                completion(name, allTimePBs, last12MonthPbs, nil)
            })
        }
    }

    func getSwimmerDetailsFrom(name:String, completion: @escaping ([SwimmerNameSearchResult]?, Error?) -> Void ){
        guard let request = try? URLRequest(url: Endpoints.allTimePbs.urlFor(swimmerName: name)) else {
            completion(nil, ScraperError.urlFormatError)
            return
        }

        let session = newSession()
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                let unwrappedData = data,
                httpResponse.statusCode == 200
            else {
                    completion(nil, ScraperError.serverError)
                    return
            }
            
            let searchResults = self.parseSwimmerSearchResults(data: unwrappedData)
            completion(searchResults, nil)
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    private func getAllTimePersonalBests(id:Int, completion: @escaping (String?, [PersonalBest]?, Error?) -> Void ){
        getPBsFrom(url: Endpoints.allTimePbs.urlFor(swimmerID: id)) { (name, pbs, error) in
            completion(name, pbs, error)
        }
    }
    
    private func getLast12MonthPersonalBests(id:Int, completion: @escaping (String?, [PersonalBest]?, Error?) -> Void ){
        getPBsFrom(url: Endpoints.last12MonthPbs.urlFor(swimmerID: id)) { (name, pbs, error) in
            completion(name, pbs, error)
        }
    }

    private func getPBsFrom(url:URL, completion: @escaping (String?, [PersonalBest]?, Error?) -> Void ){
        let session = newSession()
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard error == nil else {
                completion(nil, nil, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                let unwrappedData = data,
                httpResponse.statusCode == 200
                else {
                    completion(nil, nil, ScraperError.serverError)
                    return
            }
            
            let (name, personalBests) = self.parseHTML(data: unwrappedData)
            completion(name, personalBests, nil)
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    
    private func parseHTML(data:Data) -> (String, [PersonalBest]?) {
        guard let htmlString = String(data: data, encoding: .utf8),
              let doc = try? HTML(html: htmlString, encoding: .utf8)
        else {
            assertionFailure("Unable to read from url")
            abort()
        }
        
        let swimmerNode =  doc.xpath("//*[@id=\"outerWrapper\"]/div[2]/div[2]/p[1]/text()")
        let swimmerName:String
        switch swimmerNode {
        case let .NodeSet(nodeset: swimmerNode):
            swimmerName = (swimmerNode.text ?? "Unknown").components(separatedBy: " - ").first!
            
        default:
            swimmerName = "Unknown"
        }
        
        typealias Result = [[String]]
        var tables:[Result] = []
        
        for table in doc.xpath("//*[@id=\"rankTable\"]") {
            var results:Result = []
            for tableRow in table.xpath(".//tbody/tr") {
                var row:[String] = []
                for tableCell in tableRow.xpath(".//td"){
                    row.append(tableCell.text!.trimmingCharacters(in:.whitespaces))
                }
                results.append(row)
            }
            tables.append(results)
        }

        
        var pbs:[PersonalBest] = []
        var course:PersonalBest.Course = tables.count > 1 ? .long : .short
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        
        for table in tables {
            for resultsRow in table {
                guard resultsRow.count != 0,
                      let eventDate = dateFormatter.date(from: resultsRow[3])
                else {
                    continue
                }
                let pb = PersonalBest(name: resultsRow[0],
                                      time: resultsRow[1],
                                      timeInterval: resultsRow[1].timeValue,
                                      finaPoints: resultsRow[2],
                                      dateAttained: eventDate,
                                      meet: resultsRow[4],
                                      venue: resultsRow[5],
                                      licence: resultsRow[6],
                                      level: resultsRow[7],
                                      course: course)
                pbs.append(pb)
            }
            course = .short
        }

        return (swimmerName, pbs)
    }
 
    private func parseSwimmerSearchResults(data: Data) -> [SwimmerNameSearchResult]? {
        guard let htmlString = String(data: data, encoding: .utf8),
            let doc = try? HTML(html: htmlString, encoding: .utf8)
            else {
                assertionFailure("Unable to read from url")
                abort()
        }
        
        var results:[SwimmerNameSearchResult] = []
        
        for tableRow in doc.xpath("//*[@id=\"rankTable\"]/tbody/tr") {
            let cells = tableRow.xpath(".//td")
            guard cells.count > 0 else { continue }

            guard let idText = cells[0].text,
                  let id = Int(idText),
                  let surname = cells[1].text,
                  let firstname = cells[2].text,
                  let knownAsName = cells[3].text,
                  let YoBText = cells[4].text,
                  let genderText = cells[5].text,
                  let gender = SwimmerNameSearchResult.Gender(rawValue: genderText),
                  let club = cells[6].text
            else { continue }

            let result = SwimmerNameSearchResult.init(id: id, familyName: surname, givenName: firstname, knownAsName: knownAsName, yearOfBirth: YoBText, gender: gender, club: club)
            results.append(result)
        }
        
        return (results)
    }
    
}
