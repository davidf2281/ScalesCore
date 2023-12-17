
import Foundation

protocol Timestamped {
    typealias UnixMillis = Int
    var timestamp: UnixMillis { get }
}

protocol Persistable: Codable {
    associatedtype T: Codable, Timestamped
    var items: [T] { get }
}

protocol Persistence {
    associatedtype T: Persistable
    func persist(_ item: T) async throws
}

enum PersisterError: Error {
    case dataDirectoryLocation
    case writePermissions
    case dateRangeCreation
}

actor Persister<T: Persistable>: Persistence {
    
    private let dataDirectory: URL
    
    public init() throws {
        
        let fileManager = FileManager.default
                
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PersisterError.dataDirectoryLocation
        }
        
        self.dataDirectory = documentsURL.appendingPathComponent("PersistedSensorData")
                
        try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }
    
    func persist(_ item: T) async throws {
        
        let encoder = JSONEncoder()
        let encodedItem = try encoder.encode(item)
        
        guard let maxDateItem = item.items.max(by: { $0.timestamp > $1.timestamp}),
              let minDateItem = item.items.min(by: { $0.timestamp > $1.timestamp}) else {
            throw PersisterError.dateRangeCreation
        }
        
        let dateSeparator = "-"
        let filename = "\(maxDateItem.timestamp)" + dateSeparator + "\(minDateItem.timestamp)"
        let filePath = dataDirectory.appendingPathComponent(filename + ".json")
                
        try encodedItem.write(to: filePath, options: [.atomic])
    }
}
