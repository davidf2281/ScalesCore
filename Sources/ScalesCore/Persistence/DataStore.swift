
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

struct ArchivedReadings<T: SensorOutput, U: Sensor>: Persistable {
    let items: [StoredReading<T>]
    let sensor: U
}

import Foundation

actor HybridDataStore<T: SensorOutput, U: Sensor>: DataStore {
  
    private let sensor: U
    
    private let capacity: Int = 1000
    private let persister: Persister<ArchivedReadings<T, U>>
    
    var totalReadingsCount: Int {
        self.readings.count
    }
    
    var availableCapacity: Float {
        Float(totalReadingsCount) / Float(capacity)
    }
    
    private var readings: [StoredReading<T>]
    
    init(sensor: U) {
        self.sensor = sensor
        self.readings = []
        self.readings.reserveCapacity(capacity)
        self.persister = Persister()
    }
    
    func save(_ reading: T, date: Date) async throws {
        let storedReading = StoredReading(value: reading, date: date)
        
        readings.append(storedReading)
        
        try await serializeToDisk()
    }
    
    func retrieve(since: Date) async throws -> [StoredReading<T>] {
        return []
    }
    
    func retrieveLast() async -> StoredReading<T>? {
        return nil
    }
    
    private func serializeToDisk() async throws {
        let archivedReadings = ArchivedReadings(items: self.readings, sensor: self.sensor)
        try await persister.persist(items: archivedReadings)
    }
}

protocol Persistable: Codable {
    associatedtype T: Codable, Dateable
    var items: [T] { get }
}

protocol Persisting {
    associatedtype T: Persistable
    func persist(items: T) async throws
}

actor Persister<T: Persistable>: Persisting {
    func persist(items: T) async throws {
        let encoder = JSONEncoder()
        let result = try? encoder.encode(items)
        if let result,
           let string = String(data: result, encoding: .utf8) {
            print(string)
        }
    }
}
