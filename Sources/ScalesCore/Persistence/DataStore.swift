
import Foundation

protocol DataStore {
    associatedtype T: SensorOutput
    associatedtype U: Sensor
    var totalReadingsCount: Int { get }
    var availableCapacity: Float { get } // Value between 0 and 1
    func save(_ reading: T, sensor: U, date: Date) async throws
    func retrieve(since: Date) async throws -> [StoredReading<T, U>]
    func retrieveLast() async -> StoredReading<T, U>?
}

struct StoredReading<T: SensorOutput, U: Sensor>: Codable {
    let reading: T
    let sensor: U
    let date: Date?
    var elementSizeBytesIncludingAlignment: Int {
        MemoryLayout<Self>.stride
    }
}

enum DataStoreError: Error {
    case full
}

import Foundation

class HybridDataStore<T: SensorOutput, U: Sensor>: DataStore {
  
    private let capacity: Int = 1000
    
    var totalReadingsCount: Int {
        self.readings.count
    }
    
    var availableCapacity: Float {
        Float(totalReadingsCount) / Float(capacity)
    }
    
    private var readings: [StoredReading<T, U>]
    
    init() {
        self.readings = []
        self.readings.reserveCapacity(capacity)
    }
    
    func save(_ reading: T, sensor: U, date: Date) async throws {
        let storedReading = StoredReading(reading: reading, sensor: sensor, date: date)
        self.readings.append(storedReading)
        serializeToDisk()
    }
    
    func retrieve(since: Date) async throws -> [StoredReading<T, U>] {
        return []
    }
    
    func retrieveLast() -> StoredReading<T, U>? {
        return self.readings.last
    }
    
    private func serializeToDisk() {
        let encoder = JSONEncoder()
        let result = try? encoder.encode(self.readings)
        if let result,
           let string = String(data: result, encoding: .utf8) {
            print(string)
        }
    }
}
