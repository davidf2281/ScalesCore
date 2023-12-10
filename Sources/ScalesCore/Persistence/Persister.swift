
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
}

actor Persister<T: Persistable>: Persistence {
    
    private let dataDirectory: URL
    
    public init() throws {
        
        let fileManager = FileManager.default
        
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        
        self.dataDirectory = URL(fileURLWithPath: homeDirectory.relativePath + "/ScalesData")
        
        print("Attempting data directory creation at \(self.dataDirectory.absoluteString)")
        
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
        
        let filePath = URL(fileURLWithPath: dataDirectory.relativePath + "/" + filename)
        
        print("Attempting data file creation at \(filePath.absoluteString)")

        
        let success = FileManager.default.createFile(atPath: filePath.absoluteString, contents: encodedItem)
        
        if !success {
            throw PersisterError.failed
        }
//           let string = String(data: result, encoding: .utf8)
//            print(string)
    }
}
