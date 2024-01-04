
import Foundation

protocol DataStore<T>: AnyActor {
    associatedtype T: SensorOutput
    var totalReadingsCount: Int { get async }
    var availableCapacity: Float { get async } // Value between 0 and 1
    func save(reading: Reading<T>, date: Date) async throws
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

    let associatedSensor: AnySensor<T>
    let associatedOutputType: SensorOutputType
    
    private let capacity: Int = 100000
    private let persister: Persister<AnyStorableReading<T>>
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
        
    init(persistencePolicy: DataStorePersistencePolicy, storeName: String, associatedSensor: AnySensor<T>, associatedOutputType: SensorOutputType) throws {
        self.persistencePolicy = persistencePolicy
        self.associatedSensor = associatedSensor
        self.associatedOutputType = associatedOutputType
        self.readings = []
        self.readings.reserveCapacity(capacity)
        self.persister = try Persister<AnyStorableReading<T>>(storeName: storeName)
    }
    
    func flushToDisk() async throws {
        try await persister.persist(self.readings)
        self.lastFlushDate = Date()
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
    
    func save(reading: Reading<T>, date: Date) async throws {
                
        // TODO: Separate readings by sensor name (add to arguments here probably)
        
        let storableReading = AnyStorableReading(value: reading.value, timestamp: date.unixMillisSinceEpoch)
        self.latestReading = storableReading

        readings.append(storableReading)
        
        if shouldFlushToDisk {
            try await flushToDisk()
            self.readings.removeAll()
        }
    }
  
    func retrieve(since: Date) async throws -> [AnyStorableReading<T>] {
        
        let unixSince = since.unixMillisSinceEpoch

        // If we have nothing, return whatever the persister has
        if self.readings.isEmpty {
            if let persistedReadings = try? await persister.retrieve(from: unixSince, to: Date().unixMillisSinceEpoch) {
                return persistedReadings
            }
        }
                
        // Retrieve relevant in-memory readings
        let inMemoryReadings = self.readings.filter { reading in
            reading.timestamp >= unixSince
        }
        
        // If in-memory readings don't go back as far as our since date,
        // also hit the persister
        if let firstReading = self.readings.first, firstReading.timestamp > unixSince {
            if let persistedReadings = try? await persister.retrieve(from: unixSince, to: firstReading.timestamp) {
                return persistedReadings + inMemoryReadings
            }
        }
        
        return inMemoryReadings
    }
    
    func retrieveLatest() async -> AnyStorableReading<T>? {
        self.latestReading
    }
}
