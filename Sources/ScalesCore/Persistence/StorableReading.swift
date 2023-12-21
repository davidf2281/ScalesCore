
import Foundation

protocol StorableReading<T>: PersistableItem {
    associatedtype T: SensorOutput
    var output: T { get }
    var timestamp: Int { get }
}

struct AnyStorableReading<T: SensorOutput>: StorableReading {
    
    let output: T
    let timestamp: Timestamped.UnixMillis
    
    var value: Codable {
        self.output
    }
    
    init(value: T, timestamp: Timestamped.UnixMillis) {
        self.output = value
        self.timestamp = timestamp
    }
}
