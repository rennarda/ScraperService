import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    let pbController = PersonalBestController()
    router.get("swimmer", Int.parameter, use: pbController.swimmerPBs)
    router.get("search", String.parameter, use: pbController.searchByName)
}
