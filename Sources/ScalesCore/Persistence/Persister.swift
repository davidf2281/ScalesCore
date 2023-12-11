
import Foundation

protocol Dateable {
    var date: Date { get }
}

protocol Persistable: Codable {
    associatedtype T: Codable, Dateable
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
        guard let maxDateItem = item.items.max(by: { $0.date > $1.date}),
              let minDateItem = item.items.min(by: { $0.date > $1.date}) else {
            throw PersisterError.dateRangeCreation
        }
        
        let filename = "\(maxDateItem.date.timeIntervalSince1970)-\(minDateItem.date.timeIntervalSince1970)"
        let filePath = dataDirectory.appendingPathComponent(filename)
                
        try encodedItem.write(to: filePath, options: [.atomic, .withoutOverwriting])
    }
}
