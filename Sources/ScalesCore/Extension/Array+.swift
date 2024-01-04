
import Foundation

extension Array {
    
    // TODO: This is adapted from an old project and completely untested
    func decimate(into count: Int) -> [Self.Element] {
        guard self.isNotEmpty, count <= self.count else {
            return self
        }
        
        let step: Int = self.count / count
        var result: [Element] = []
        for (index, element) in self.enumerated() {
            if index % step == 0 {
                result.append(element)
            }
        }
        
        return result
    }
}

extension Array {
    func nextIndexWrapping(index: Int) -> Int {
        
        let incrementedIndex = index + 1
        
        if (0..<self.endIndex).contains(incrementedIndex) {
            return incrementedIndex
        }
        
        return 0
    }
}

extension Array {
    var isNotEmpty: Bool {
        !self.isEmpty
    }
}

public extension Array {
    subscript(safe index: Int) -> Element? {
        guard self.isNotEmpty, index >= 0, index < endIndex else {
            return nil
        }
        
        return self[index]
    }
}

extension Array {
    
    func averaged<T: SensorOutput>(window: Timestamped.UnixMillis) throws -> [AnyStorableReading<T>] where Element == AnyStorableReading<T> {
        
        guard self.isNotEmpty else {
            return []
        }
        
        // Collect all readings into window buckets, for later averaging
        var windowBuckets: [[AnyStorableReading<T>]] = []
        var currentBucket: [AnyStorableReading<T>] = []
        
        var currentWindow: TimestampRange = try TimestampRange(from: self.first!.timestamp,
                                                           to: self.first!.timestamp + window)
        for reading in self {
            
            if currentWindow.doesNotContain(reading.timestamp) {
                windowBuckets.append(currentBucket)
                currentBucket = []
                currentWindow = try TimestampRange(from: reading.timestamp, to: reading.timestamp + window)
            }
            
            currentBucket.append(reading)
        }
        
        // Do the averaging
        return windowBuckets.compactMap { (bucket: [AnyStorableReading<T>]) -> AnyStorableReading<T>? in
            
            var outputAccumulator: T = 0
            var timestampAccumulator: Timestamped.UnixMillis = 0
            for reading in bucket {
                outputAccumulator += reading.output
                timestampAccumulator += reading.timestamp
            }
            
            guard let castCount = T(exactly: bucket.count) else {
                return nil
            }
            
            return AnyStorableReading(value: outputAccumulator / castCount, timestamp: timestampAccumulator / bucket.count)
        }
    }
}
