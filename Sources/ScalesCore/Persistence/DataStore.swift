
import Foundation

public protocol DataStore {
    associatedtype SensorOutput
    func save(_ reading: SensorOutput) async throws
    func retrieve(count: Int) async throws -> [StoredReading<SensorOutput>]
}

public struct StoredReading<T> {
    let reading: T
    let date: Date?
    var elementSizeBytesIncludingAlignment: Int {
        MemoryLayout<Self>.stride
    }
}

public class RAMDataStore<T: SensorOutput>: DataStore {
    
    private var readings: [StoredReading<T>] = []
    
    public func save(_ reading: T) throws {
        self.readings.append(.init(reading: reading, date: nil))
    }
    
    public func retrieve(count: Int) throws -> [StoredReading<T>] {
        self.readings.suffix(count)
    }
}
