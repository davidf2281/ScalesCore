
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
    private let itemsProvider = CachingPersistedItemsProvider<T>()
    public init(storeName: String) throws {
        
        let fileManager = FileManager.default
                
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PersisterError.dataDirectoryLocation
        }
        
        self.dataDirectory = documentsURL
            .appendingPathComponent("PersistedData")
            .appendingPathComponent(storeName)
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
                
        let filename = try TimestampRange(from: minDateItem.timestamp, to: maxDateItem.timestamp).stringRepresentation + ".json"
        let containingFolderName = try TimestampRangeProvider.containingRange(for: firstElement.timestamp).stringRepresentation
        
        let containingFolder = self.dataDirectory.appendingPathComponent(containingFolderName)
        try FileManager.default.createDirectory(at: containingFolder, withIntermediateDirectories: true)

        let filePath = containingFolder.appendingPathComponent(filename)
                
        try encodedPersistables.write(to: filePath, options: [.atomic])
    }
    
    func retrieve(from: Timestamped.UnixMillis, to: Timestamped.UnixMillis) throws -> [T] {
        
        // If the search starts before the epoch, nudge it up to start at the epoch
        let adjustedFrom: Timestamped.UnixMillis = from.isBeforeEpoch ? TimestampRangeProvider.startingEpoch : from
        let searchRange = try TimestampRange(from: adjustedFrom, to: to)

        // Find the ranges containing the start and end of our search, plus one to cover data whose
        // timestamps overflow its containing folder's nominal timestamp range
        let ranges = try TimestampRangeProvider.containingRangesPlusOne(for: adjustedFrom, to: to)
        
        var matchingItems: [T] = []

        for currentContainerRange in ranges {
            
            let searchFolderName = currentContainerRange.stringRepresentation
            let searchFolder = self.dataDirectory.appendingPathComponent(searchFolderName)
            
            // Find all files within or overlapping our search range
            guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: searchFolder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }
            
            // Consider only files matching our timestamp naming pattern, and within relevant timestamp range
            let filteredFileURLs = fileURLs.filter { fileURL in
                if let range = try? TimestampRange(string: fileURL.lastPathComponent.replacingOccurrences(of: ".json", with: "")) { // TODO: Make this nicer
                    return range.overlaps(range: searchRange)
                } else {
                    return false
                }
            }
            
            guard filteredFileURLs.isNotEmpty else {
                continue
            }
            
            // Get data from the files
            for fileURL in filteredFileURLs {
                let persistedItems = try itemsProvider.items(for: fileURL)
                
                // Get values within our desired timestamp range
                matchingItems += persistedItems.filter { searchRange.contains($0.timestamp) }
            }
        }
        
        return matchingItems
    }
}

class CachingPersistedItemsProvider<T: PersistableItem> {
    
    private let decoder = JSONDecoder()
    private var cache: [URL: [T]] = [:]
    private let logger = Logger(name: "CachingJSONPersistedItemsProvider")
    
    func items(for fileURL: URL) throws -> [T] {
        
        if let cachedJSONData = cache[fileURL] {
            return cachedJSONData
        }
        
        let jsonData = try Data(contentsOf: fileURL)
        let persistedItems = try decoder.decode([T].self, from: jsonData)
        cache[fileURL] = persistedItems
        return persistedItems
    }
}

struct TimestampRange {
    
    let from: Timestamped.UnixMillis
    let to: Timestamped.UnixMillis
    
    private static let separator = "-"
    
    enum TimestampRangeError: Error {
        case invalidStringRepresentation
        case invalidRange
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
    
    func isFullyBefore(_ timestamp: Timestamped.UnixMillis) -> Bool {
        self.to < timestamp
    }
    
    func isFullyAfter(_ timestamp: Timestamped.UnixMillis) -> Bool {
        self.from > timestamp
    }
    
    func overlaps(range: Self) -> Bool {
        (self.to > range.from && self.to < range.to) ||
        (self.from > range.from && self.from < range.to) ||
        (self.from < range.from && self.from > range.to) ||
        (self.from > range.from && self.to < range.to) ||
        self.from == range.from ||
        self.to == range.to
    }
    
    init(from: Timestamped.UnixMillis, to: Timestamped.UnixMillis) throws {
        guard from < to else {
            throw TimestampRangeError.invalidRange
        }
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
    
    /* --- DO NOT CHANGE these two properties as this would break existing folder structures --- */
    static let startingEpoch: Timestamped.UnixMillis = 1702166400000 // Midnight, 10th December 2023
    static let rangeLength: Millis = 604800000 // One week.
    /* ----------------------------------------------------------------------------------------- */
    
    enum TimestampRangeProviderError: Error {
        case timestampBeforeEpoch
    }
    
    static func containingRange(for timeStamp: Timestamped.UnixMillis) throws -> TimestampRange {
        
        guard !timeStamp.isBeforeEpoch else {
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
        
        return try TimestampRange(from: start , to: end)
    }
    
    /// - Returns: An array of ranges spanning the from and to timestamps, plus one further to cover data whose timestamps overflow its containing folder's nominal timestamp range
    static func containingRangesPlusOne(for from: Timestamped.UnixMillis, to: Timestamped.UnixMillis) throws -> [TimestampRange] {
        
        var ranges: [TimestampRange] = []
        
        let startingRange = try containingRange(for: from)
        ranges.append(startingRange)
        
        var finished = false
        var currentRange = startingRange
        
        while(!finished) {
            let nextRange = try TimestampRangeProvider.nextContainingRange(after: currentRange)
            ranges.append(nextRange)
            if nextRange.isFullyAfter(to) {
                finished = true
            }
            currentRange = nextRange
        }
        
        return ranges
    }

    
    static func nextContainingRange(after: TimestampRange) throws -> TimestampRange {
        return try Self.containingRange(for: after.to + 1)
    }
}

extension Timestamped.UnixMillis {
    var isBeforeEpoch: Bool {
        self < TimestampRangeProvider.startingEpoch
    }
}
