
import Foundation

protocol DataStore<T>: AnyActor {
    associatedtype T: SensorOutput
    var totalReadingsCount: Int { get async }
    var availableCapacity: Float { get async } // Value between 0 and 1
    func save(reading: T, date: Date) async throws
    func retrieve(since: Date) async throws -> [AnyStorableReading<T>]
    func retrieveLatest() async -> AnyStorableReading<T>?
}

enum DataStorePersistencePolicy {
    case onFullToCapacity
    case onFullToCapacityAndToSchedule(interval: TimeInterval)
}

enum DataStoreError: Error {
    case full
}

actor HybridDataStore<T: SensorOutput>: DataStore {

    private let capacity: Int = 50000
    private let persister: Persister
    private var lastFlushDate: Date = Date()
    private var persistencePolicy: DataStorePersistencePolicy
    private var readings: [AnyStorableReading<T>]
    private var latestReading: AnyStorableReading<T>? = nil
    
    var totalReadingsCount: Int {
        self.readings.count
    }
    
    var availableCapacity: Float {
        Float(totalReadingsCount) / Float(capacity)
    }
        
    init(persistencePolicy: DataStorePersistencePolicy = .onFullToCapacity) throws {
        self.persistencePolicy = persistencePolicy
        self.readings = []
        self.readings.reserveCapacity(capacity)
        self.persister = try Persister()
    }
    
    func save(reading: T, date: Date) async throws {
                
        let storableReading = AnyStorableReading(value: reading, date: date)
        self.latestReading = storableReading

        readings.append(storableReading)
        
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
                if -self.lastFlushDate.timeIntervalSinceNow > interval {
                    return true
                } else {
                    return false
                }
        }
    }
  
    func retrieve(since: Date) async throws -> [AnyStorableReading<T>] {
        [] // TODO: Implement
    }
    
    func retrieveLatest() async -> AnyStorableReading<T>? {
        self.latestReading
    }
    
    private func flushToDisk() async throws {
        try await persister.persist(self.readings)
        self.lastFlushDate = Date()
    }
}
