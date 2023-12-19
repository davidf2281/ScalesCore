
import Foundation

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
