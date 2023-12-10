
import Foundation

protocol DataStore: AnyActor {
    associatedtype T: SensorOutput
    associatedtype U: Sensor
    var totalReadingsCount: Int { get async }
    var availableCapacity: Float { get async } // Value between 0 and 1
    func save(_ reading: T, date: Date) async throws
    func retrieve(since: Date) async throws -> [StoredReading<T>]
    func retrieveLast() async -> StoredReading<T>?
}

protocol Dateable {
    var date: Date { get }
}

struct StoredReading<T: SensorOutput>: Codable, Dateable {
    let value: T
    let date: Date
    var elementSizeBytesIncludingAlignment: Int {
        MemoryLayout<Self>.stride
    }
}

enum DataStoreError: Error {
    case full
}

struct ArchivedReadings<T: SensorOutput>: Persistable {
    var name: String
    let outputType: SensorOutputType
    var location: SensorLocation
    let items: [StoredReading<T>]
}

import Foundation

actor HybridDataStore<T: SensorOutput, U: Sensor>: DataStore {
  
    private let sensor: U
    
    private let capacity: Int = 100
    private let persister: Persister<ArchivedReadings<T>>
    
    var totalReadingsCount: Int {
        self.readings.count
    }
    
    var availableCapacity: Float {
        Float(totalReadingsCount) / Float(capacity)
    }
    
    private var readings: [StoredReading<T>]
    
    init(sensor: U) throws {
        self.sensor = sensor
        self.readings = []
        self.readings.reserveCapacity(capacity)
        self.persister = try Persister()
    }
    
    func save(_ reading: T, date: Date) async throws {
        let storedReading = StoredReading(value: reading, date: date)
        
        readings.append(storedReading)
        
        if readings.count >= self.capacity {
            try await flushToDisk()
            self.readings.removeAll()
        }
    }
    
    func retrieve(since: Date) async throws -> [StoredReading<T>] {
        return []
    }
    
    func retrieveLast() async -> StoredReading<T>? {
        return nil
    }
    
    private func flushToDisk() async throws {
        let archivedReadings = ArchivedReadings(name: self.sensor.name, outputType: self.sensor.outputType, location: self.sensor.location, items: self.readings)
        try await persister.persist(archivedReadings)
    }
}
