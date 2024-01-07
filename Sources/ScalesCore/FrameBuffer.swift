
public class FrameBuffer {
    
    // TODO: Eliminate separate width and height properties in favour of Size.
    let width: Int
    let height: Int
    var size: Size { .init(width: width, height: height) }
    
    public private(set) var pixels: [Color24]
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.pixels = Array(repeating: .black, count: width * height)
    }
    
    func clear() {
        // TODO: Optimise
        self.pixels = Array(repeating: .black, count: width * height)
    }
    
    func plotPixel(_ x: Int, _ y: Int, color: Color24) {
        let index = index(for: x, y)
        if index < pixels.count {
            pixels[index] = color
        }
    }
    
    func pixel(at x: Int, _ y: Int) -> Color24? {
        return pixels[safe: index(for: x, y)]
    }
    
    private func index(for x: Int, _ y: Int) -> Int {
        return width * y + x
    }
    
    /// Transpose our buffer array from a series of rows to a series of columns
    public var swappedWidthForHeight: FrameBuffer {
        get throws {
            try Task.checkCancellation()
            let rotatedBuffer = FrameBuffer(width: self.size.height, height: self.size.width)
            var newIndex = self.pixels.count - 1
            for i in 0..<self.size.width {
                for j in 1...self.size.height {
                    let oldIndex = (self.size.width * (self.size.height - j)) + i
                    rotatedBuffer.pixels[newIndex] = self.pixels[oldIndex]
                    newIndex -= 1
                }
            }
            
            return rotatedBuffer
        }
    }
}
