
import Foundation
import RealmSwift

public protocol DataStore {
    associatedtype SensorOutput
    var totalReadingsCount: Int { get }
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

public class RAMDataStore<T: SensorOutput>: Object, DataStore {
    
    public var totalReadingsCount: Int {
        self.readings.count
    }
    
    private var readings: [StoredReading<T>] = []
    
    @Persisted var realmyThing: String
    
    public func save(_ reading: T) throws {
        self.readings.append(.init(reading: reading, date: nil))
    }
    
    public func retrieve(count: Int) throws -> [StoredReading<T>] {
        self.readings.suffix(count)
    }
}
