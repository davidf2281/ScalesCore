
import Foundation

public struct Logger {
    
    private let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func log(_ message: String) {
        let now = Date()
        print("\(self.name) \(now): \(message)")
    }
}
