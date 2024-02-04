import Foundation

// You see why I can't make this generic? In the key line, we have to say `int` to talk to FMResultSet.
extension FMDatabaseQueue {
    func int(forQuery query: String, arguments: [Any] = []) -> Int? {
        var outcome: Int?
        self.inDatabase() { db in
            outcome = db.int(forQuery: query, arguments: arguments)
        }
        return outcome
    }
    func string(forQuery query: String, arguments: [Any] = []) -> String? {
        var outcome: String?
        self.inDatabase() { db in
            outcome = db.string(forQuery: query, arguments: arguments)
        }
        return outcome
    }
}

// same here, I have to construct these shortcuts for myself one by one
extension FMDatabase {
    func int(forQuery query: String, arguments: [Any] = []) -> Int? {
        var outcome: Int?
        if let result = self.executeQuery(query, withArgumentsIn: arguments) {
            if result.next() {
                outcome = Int(result.int(forColumnIndex: 0))
            }
        }
        return outcome
    }
    func string(forQuery query: String, arguments: [Any] = []) -> String? {
        var outcome: String?
        if let result = self.executeQuery(query, withArgumentsIn: arguments) {
            if result.next() {
                outcome = result.string(forColumnIndex: 0)
            }
        }
        return outcome
    }
}

extension FMDatabase {
    func executeUpdate(_ sql: String) {
        executeUpdate(sql, withArgumentsIn: [])
    }
}
