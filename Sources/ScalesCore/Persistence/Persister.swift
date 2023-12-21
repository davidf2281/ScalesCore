
import Foundation

protocol Timestamped {
    typealias UnixMillis = Int
    var timestamp: UnixMillis { get }
}

extension Timestamped.UnixMillis {
    static var oneMinute: Self = 60000
    static var oneHour: Self = 3600000
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
        
        guard let maxDateItem = persistables.max(by: { $1.timestamp > $0.timestamp}),
              let minDateItem = persistables.min(by: { $1.timestamp > $0.timestamp}) else {
            throw PersisterError.dateRangeCreation
        }
                
        let filename = TimestampRange(from: minDateItem.timestamp, to: maxDateItem.timestamp).stringRepresentation + ".json"
        let containingFolderName = try TimestampRangeProvider.containingRange(for: firstElement.timestamp).stringRepresentation
        
        let containingFolder = self.dataDirectory.appendingPathComponent(containingFolderName)
        try FileManager.default.createDirectory(at: containingFolder, withIntermediateDirectories: true)

        let filePath = containingFolder.appendingPathComponent(filename)
                
        try encodedPersistables.write(to: filePath, options: [.atomic])
    }
    
    // TODO: Write some tests for this craziness, especially the end-loop logic to move to the next folder
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
                // Note: we'll get to here if we've done an iteration and got to the point of not being able
                // to find the next folder. So we don't throw an error here; we return our results.
                // TODO: Finesse things so we're not relying on an error being thrown
                return matchingItems
            }
            
            let filteredFileURLs = fileURLs.filter { fileURL in
                if let range = try? TimestampRange(string: fileURL.lastPathComponent.replacingOccurrences(of: ".json", with: "")) { // TODO: Make this nicer
                    return range.overlaps(range: searchRange)
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
    
    func doesNotContain(_ timestamp: Timestamped.UnixMillis) -> Bool {
        !self.contains(timestamp)
    }
    
    func overlaps(range: Self) -> Bool {
        (self.to > range.from && self.to < range.to) ||
        (self.from > range.from && self.from < range.to) ||
        (self.from < range.from && self.from > range.to) ||
        (self.from > range.from && self.to < range.to) ||
        self.from == range.from ||
        self.to == range.to
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

