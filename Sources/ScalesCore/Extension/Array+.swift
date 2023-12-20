
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
