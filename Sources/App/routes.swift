import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    let scraper = Scraper()
    router.get("scraper", Int.parameter) { req -> Future<Swimmer> in

        let promise:Promise<Swimmer> = req.eventLoop.newPromise()

        let id = try req.parameters.next(Int.self)
        scraper.getPersonalBests(id: id, completion: { (name, allTimePBs, last12MonthPBs, error)  in
            if error == nil,
               let pbs = allTimePBs,
                let name = name
            {
                let swimmer = Swimmer.init(name: name, id: id, allTimePbs: pbs, last12MonthPbs: last12MonthPBs)
                promise.succeed(result: swimmer)
            }
        })
        
        return promise.futureResult
    }
    
    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
}
