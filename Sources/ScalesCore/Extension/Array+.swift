
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

extension Array {
    subscript(safe index: Int) -> Element? {
        guard self.isNotEmpty, index >= 0, index < endIndex else {
            return nil
        }
        
        return self[index]
    }
}

extension Array {
    
    func averaged<T>(window: Timestamped.UnixMillis) -> [AnyStorableReading<T>] where Element == AnyStorableReading<T> {
        
        guard self.isNotEmpty else {
            return []
        }
        
        // Collect all readings into window buckets, for later averaging
        var windowBuckets: [[AnyStorableReading<T>]] = []
        var currentBucket: [AnyStorableReading<T>] = []
        var currentWindow: TimestampRange = TimestampRange(from: self.first!.timestamp, to: self.first!.timestamp + window)
        
        for reading in self {
            if currentWindow.doesNotContain(reading.timestamp) {
                windowBuckets.append(currentBucket)
                currentBucket = []
                currentWindow = TimestampRange(from: reading.timestamp, to: reading.timestamp + window)
            }
            currentBucket.append(reading)
        }
        
        // Do the averaging
        return windowBuckets.compactMap { bucket in
  
            let averagedTimestamp = bucket.map { Float($0.timestamp) }.averaged
            let averagedOutput = bucket.map { $0.output }.averaged

            return AnyStorableReading(value: T(averagedOutput), timestamp: Timestamped.UnixMillis(averagedTimestamp))
        }
    }
}

extension Array where Element: FloatingPoint {
    
    var averaged: Element {
        var accumulator: Element = 0
        for element in self {
            accumulator += element
        }
        
        return accumulator / Element(self.count)
    }
}
