
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

struct StoredReading<T: SensorOutput>: Codable, Dateable {
    let value: T
    let date: Date
    var elementSizeBytesIncludingAlignment: Int {
        MemoryLayout<Self>.stride
    }
}

enum DataStorePersistencePolicy {
    case onFullToCapacity
    case onFullToCapacityAndToSchedule(interval: TimeInterval)
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

actor HybridDataStore<T: SensorOutput, U: Sensor>: DataStore {
  
    private let sensor: U
    
    private let capacity: Int = 50000
    private let persister: Persister<ArchivedReadings<T>>
    private var lastFlushDate: Date = Date()
    private var persistencePolicy: DataStorePersistencePolicy
    
    var totalReadingsCount: Int {
        self.readings.count
    }
    
    var availableCapacity: Float {
        Float(totalReadingsCount) / Float(capacity)
    }
    
    private var readings: [StoredReading<T>]
    
    init(sensor: U, persistencePolicy: DataStorePersistencePolicy = .onFullToCapacity) throws {
        self.sensor = sensor
        self.persistencePolicy = persistencePolicy
        self.readings = []
        self.readings.reserveCapacity(capacity)
        self.persister = try Persister()
    }
    
    func save(_ reading: T, date: Date) async throws {
        let storedReading = StoredReading(value: reading, date: date)
        
        readings.append(storedReading)
        
        if shouldFlushToDisk {
            try await flushToDisk()
            self.readings.removeAll()
        }
    }
    
    private var shouldFlushToDisk: Bool {
        
        if readings.count >= self.capacity {
            return true
        }
        
        switch self.persistencePolicy {
                
            case .onFullToCapacity:
                return false
                
            case .onFullToCapacityAndToSchedule(let interval):
                if interval > -self.lastFlushDate.timeIntervalSinceNow {
                    return true
                } else {
                    return false
                }
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
        self.lastFlushDate = Date()
    }
}
