
import Foundation

protocol StorableReading<T>: PersistableItem {
    associatedtype T: SensorOutput
    var output: T { get }
    var timestamp: Int { get }
}

struct AnyStorableReading<T: SensorOutput>: StorableReading {
    
    let output: T
    let timestamp: Int
    
    var value: Codable {
        self.output
    }
    
    init(value: T, date: Date) {
        self.output = value
        self.timestamp = date.unixMillisSinceEpoch
    }
}
