
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

struct StoredReading<T: SensorOutput>: Codable {
    let reading: T
    let date: Date?
    var elementSizeBytesIncludingAlignment: Int {
        MemoryLayout<Self>.stride
    }
}

enum DataStoreError: Error {
    case full
}

struct ArchivedReadings<T: SensorOutput, U: Sensor>: Codable {
    let readings: [StoredReading<T>]
    let sensor: U
}

import Foundation

actor HybridDataStore<T: SensorOutput, U: Sensor>: DataStore {
  
    private let sensor: U
    
    private let capacity: Int = 1000
    
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
    }
    
    func save(_ reading: T, date: Date) async throws {
        let storedReading = StoredReading(reading: reading, date: date)
        
        readings.append(storedReading)
        
        serializeToDisk()
    }
    
    func retrieve(since: Date) async throws -> [StoredReading<T>] {
        return []
    }
    
    func retrieveLast() async -> StoredReading<T>? {
        return nil
    }
    
    private func serializeToDisk() {
        let archivedReadings = ArchivedReadings(readings: self.readings, sensor: self.sensor)
        let encoder = JSONEncoder()
        let result = try? encoder.encode(archivedReadings)
        if let result,
           let string = String(data: result, encoding: .utf8) {
            print(string)
        }
    }
}
