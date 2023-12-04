
import Foundation

protocol DataStore {
    associatedtype SensorOutput
    var totalReadingsCount: Int { get }
    var availableCapacity: Float { get } // Value between 0 and 1
    func save(_ reading: SensorOutput, date: Date) async throws
    func retrieve(since: Date) async throws -> [StoredReading<SensorOutput>]
    func retrieveLast() async -> StoredReading<SensorOutput>?
}

struct StoredReading<T> {
    let reading: T
    let date: Date?
    var elementSizeBytesIncludingAlignment: Int {
        MemoryLayout<Self>.stride
    }
}

enum DataStoreError: Error {
    case full
}

import Foundation

class HybridDataStore<T: SensorOutput>: DataStore {
  
    private let capacity: Int = 1000
    private var saveTask: Task<T, Error>?
    
    var totalReadingsCount: Int {
        self.readings.count
    }
    
    var availableCapacity: Float {
        Float(totalReadingsCount) / Float(capacity)
    }
    
    private var readings: [StoredReading<T>]
    
    init() {
        self.readings = []
        self.readings.reserveCapacity(capacity)
    }
    
    func save(_ reading: T, date: Date) async throws {
        self.saveTask = Task { [weak self] in
            let storedReading = StoredReading(reading: reading, date: date)
            self?.readings.append(storedReading)
            return reading
        }
    }
    
    func retrieve(since: Date) async throws -> [StoredReading<T>] {
        return []
    }
    
    func retrieveLast() -> StoredReading<T>? {
        return self.readings.last
    }
}
