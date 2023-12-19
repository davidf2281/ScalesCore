
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
    case nothingToPersist
    case dataNotFound
}

actor Persister<T: PersistableItem> {
    
    private let dataDirectory: URL
    
    public init(storeName: String) throws {
        
        let fileManager = FileManager.default
                
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PersisterError.dataDirectoryLocation
        }
        
        self.dataDirectory = documentsURL
            .appendingPathComponent("PersistedData")
            .appendingPathComponent(storeName)
                
        print("Creating directory at \(self.dataDirectory.absoluteString)")
        
        try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }
    
    func persist(_ persistables: [T]) async throws {
        
        guard let firstElement = persistables.first else {
            throw PersisterError.nothingToPersist
        }
        
        let encoder = JSONEncoder()
        let encodedPersistables = try encoder.encode(persistables)
        
        guard let maxDateItem = persistables.max(by: { $0.timestamp > $1.timestamp}),
              let minDateItem = persistables.min(by: { $0.timestamp > $1.timestamp}) else {
            throw PersisterError.dateRangeCreation
        }
                
        let filename = TimestampRange(from: minDateItem.timestamp, to: maxDateItem.timestamp).stringRepresentation + ".json"
        let containingFolderName = try TimestampRangeProvider.containingRange(for: firstElement.timestamp).stringRepresentation
        let filePath = self.dataDirectory.appendingPathComponent(containingFolderName).appendingPathComponent(filename)
                
        try encodedPersistables.write(to: filePath, options: [.atomic])
    }
    
    func retrieve(from: Timestamped.UnixMillis, to: Timestamped.UnixMillis) throws -> [T] {
        
        let searchRange = TimestampRange(from: from, to: to)
        var matchingItems: [T] = []
        var finished = false

        // Find the directory containing the start of our search range
        let startingContainerRange = try TimestampRangeProvider.containingRange(for: from)
        
        var currentContainerRange = startingContainerRange
        
        while !finished {
            let searchFolderName = currentContainerRange.stringRepresentation
            let searchFolder = self.dataDirectory.appendingPathComponent(searchFolderName)
            
            // Find all files within or overlapping our search range
            guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: searchFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                return matchingItems
            }
            
            let filteredFileURLs = fileURLs.filter { fileURL in
                if let range = try? TimestampRange(string: fileURL.lastPathComponent) {
                    return range.contains(from) || range.contains(to)
                } else {
                    return false
                }
            }
            
            guard filteredFileURLs.isNotEmpty else {
                return matchingItems
            }
            
            // Get data from the files
            let decoder = JSONDecoder()
            for fileURL in filteredFileURLs {
                let jsonData = try Data(contentsOf: fileURL)
                let persistedItems = try decoder.decode([T].self, from: jsonData)
                
                // Get values within our desired timestamp range
                matchingItems += persistedItems.filter { searchRange.contains($0.timestamp) }
                
                guard let lastItem = persistedItems.last else {
                    return matchingItems
                }
                
                // Have we finished?
                finished = lastItem.timestamp > to

                if finished {
                    break
                }
            }
            
            // Prepare to search the next folder
            currentContainerRange = try TimestampRangeProvider.nextContainingRange(after: currentContainerRange)
        }
        
        return matchingItems
    }
}

struct TimestampRange {
    
    let from: Timestamped.UnixMillis
    let to: Timestamped.UnixMillis
    
    private static let separator = "-"
    
    enum TimestampRangeError: Error {
        case invalidStringRepresentation
    }
    
    var stringRepresentation: String {
        String(from) + Self.separator + String(to)
    }
    
    func contains(_ timestamp: Timestamped.UnixMillis) -> Bool {
        self.from <= timestamp && self.to >= timestamp
    }
    
    init(from: Timestamped.UnixMillis, to: Timestamped.UnixMillis) {
        self.from = from
        self.to = to
    }
    
    init(string: String) throws {
        
        let components = string.components(separatedBy: Self.separator)
        
        guard let fromString = components[safe: 0],
              let toString = components[safe: 1],
              let from = Timestamped.UnixMillis(fromString),
              let to = Timestamped.UnixMillis(toString) 
        else {
            throw TimestampRangeError.invalidStringRepresentation
        }
        
        self.from = from
        self.to = to
    }
}

enum TimestampRangeProvider {
    
    typealias Millis = Int
    
    static let startingEpoch: Timestamped.UnixMillis = 1702166400000 // Midnight, 10th December 2023
    static let rangeLength: Millis = 604800000 // One week
    
    enum TimestampRangeProviderError: Error {
        case timestampBeforeEpoch
    }
    
    static func containingRange(for timeStamp: Timestamped.UnixMillis) throws -> TimestampRange {
        
        guard timeStamp >= Self.startingEpoch else {
            throw TimestampRangeProviderError.timestampBeforeEpoch
        }
        
        // Start with the epoch, which we know to be in the past,
        // and add rangeLength until greater than or equal to timeStamp
        
        var comparisonTime = Self.startingEpoch
        
        while comparisonTime < timeStamp {
            comparisonTime += Self.rangeLength
        }
        
        let start = comparisonTime - Self.rangeLength
        let end = comparisonTime
        
        return TimestampRange(from: start , to: end)
    }
    
    static func nextContainingRange(after: TimestampRange) throws -> TimestampRange {
        return try Self.containingRange(for: after.to + 1)
    }
}

