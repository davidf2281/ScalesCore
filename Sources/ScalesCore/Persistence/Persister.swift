
import Foundation

protocol Timestamped {
    typealias UnixMillis = Int
    var timestamp: UnixMillis { get }
}

protocol PersistableItem: Codable, Timestamped {
    var value: Codable { get }
}

enum PersisterError: Error {
    case dataDirectoryLocation
    case writePermissions
    case dateRangeCreation
}

actor Persister<T: PersistableItem> {
    
    private let dataDirectory: URL
    
    public init(storeName: String) throws {
        
        let fileManager = FileManager.default
                
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PersisterError.dataDirectoryLocation
        }
        
        self.dataDirectory = documentsURL
            .appendingPathComponent("PersistedSensorData")
            .appendingPathComponent(storeName)
                
        print("Creating directory at \(self.dataDirectory.absoluteString)")
        
        try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }
    
    func persist(_ persistables: [T]) async throws {
        
        let encoder = JSONEncoder()
        let encodedPersistables = try encoder.encode(persistables)
        
        guard let maxDateItem = persistables.max(by: { $0.timestamp > $1.timestamp}),
              let minDateItem = persistables.min(by: { $0.timestamp > $1.timestamp}) else {
            throw PersisterError.dateRangeCreation
        }
        
        let dateSeparator = "-"
        let filename = "\(maxDateItem.timestamp)" + dateSeparator + "\(minDateItem.timestamp)"
        let filePath = dataDirectory.appendingPathComponent(filename + ".json")
                
        try encodedPersistables.write(to: filePath, options: [.atomic])
    }
    
    func retrieve(from: Timestamped.UnixMillis, to: Timestamped.UnixMillis) -> [T]? {
        []
    }
}
