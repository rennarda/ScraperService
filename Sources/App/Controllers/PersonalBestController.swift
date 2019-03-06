//
//  PersonalBestController.swift
//  App
//
//  Created by Andrew Rennard - Lines of Business North and Nations on 06/03/2019.
//

import Vapor

final class PersonalBestController {

    let scraper = Scraper()
    
    func swimmerPBs(_ req: Request) throws -> Future<Swimmer> {
        let logger = try req.make(Logger.self)
        let promise:Promise<Swimmer> = req.eventLoop.newPromise()
        let id = try req.parameters.next(Int.self)
        logger.info("Getting PBs for swimmer ID: \(id)")

        scraper.getPersonalBests(id: id, completion: { (name, allTimePBs, last12MonthPBs, error)  in
            if error == nil,
                let pbs = allTimePBs,
                let name = name
            {
                let swimmer = Swimmer.init(name: name, id: id, allTimePbs: pbs, last12MonthPbs: last12MonthPBs)
                promise.succeed(result: swimmer)
            }
            else if let error = error {
                logger.error("Error: unable to find swimmer ID \(id): \(error)")
                promise.fail(error: error)
            }
        })
        return promise.futureResult
    }

    func searchByName(_ req: Request) throws -> Future<[SwimmerNameSearchResult]> {
        let logger = try req.make(Logger.self)
        let promise:Promise<[SwimmerNameSearchResult]> = req.eventLoop.newPromise()
        let name = try req.parameters.next(String.self)
        logger.info("Searching for swimming: \(name)")

        scraper.getSwimmerDetailsFrom(name: name) { (results, error) in
            if let swimmers = results {
                promise.succeed(result: swimmers)
            }
            else if let error = error {
                logger.error("Error: unable to find swimmer \(name): \(error)")
                promise.fail(error: error)
            }
        }
        return promise.futureResult
    }

    
    
    func test(_ req: Request) throws -> String {
        return "Hi"
    }
    
}
