
import Foundation

struct Logger {
    
    let name: String
    
    func log(_ message: String) {
        let now = Date()
        print("\(self.name) \(now): \(message)")
    }
}
