
import Foundation

protocol Persistable: Codable {
    associatedtype T: Codable, Dateable
    var items: [T] { get }
}

protocol Persistence {
    associatedtype T: Persistable
    func persist(_ item: T) async throws
}

enum PersisterError: Error {
    case failed
    case writePermissions
}

actor Persister<T: Persistable>: Persistence {
    
    private let dataDirectory: URL
    
    public init() throws {
        
        let fileManager = FileManager.default
                
        guard let documentsURL = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first else {
            throw PersisterError.failed
        }
        
        self.dataDirectory = documentsURL.appendingPathComponent("PersistedSensorData")
        
        print("Attempting data directory creation at \(self.dataDirectory)")
        
        try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }
    
    func persist(_ item: T) async throws {
        let encoder = JSONEncoder()
        let encodedItem = try encoder.encode(item)
        guard let maxDateItem = item.items.max(by: { $0.date > $1.date}),
              let minDateItem = item.items.min(by: { $0.date > $1.date}) else {
            throw PersisterError.failed
        }
        
        let filename = "\(maxDateItem.date.timeIntervalSince1970)-\(minDateItem.date.timeIntervalSince1970)"
        
        let filePath = dataDirectory.appendingPathComponent(filename)
        
        print("Attempting data file creation at \(filePath)")
        
        do {
            try encodedItem.write(to: filePath, options: [.atomic, .withoutOverwriting])
        } catch {
            print("Unable to write to file")
            throw error
        }
    }
}
