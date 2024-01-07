
public actor FrameBuffer {
    
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
    
    func clear() async {
        // TODO: Optimise
        self.pixels = Array(repeating: .black, count: width * height)
    }
    
    func plotPixel(_ x: Int, _ y: Int, color: Color24) async {
        let index = index(for: x, y)
        await plotPixel(index: index, color: color)
    }
    
    func plotPixel(index: Int, color: Color24) async {
        if index < pixels.count {
            pixels[index] = color
        }
    }
    
    func pixel(at x: Int, _ y: Int) async -> Color24? {
        return pixels[safe: index(for: x, y)]
    }
    
    private func index(for x: Int, _ y: Int) -> Int {
        return width * y + x
    }
    
    /// Transpose our buffer array from a series of rows to a series of columns
    public var swappedWidthForHeight: FrameBuffer {
        get async throws {
            try Task.checkCancellation()
            let rotatedBuffer = FrameBuffer(width: self.size.height, height: self.size.width)
            var newIndex = self.pixels.count - 1
            for i in 0..<self.size.width {
                for j in 1...self.size.height {
                    let oldIndex = (self.size.width * (self.size.height - j)) + i
                    let pixel = self.pixels[oldIndex]
                    await rotatedBuffer.plotPixel(index: newIndex, color: pixel)
                    newIndex -= 1
                }
            }
            
            return rotatedBuffer
        }
    }
}

extension FrameBuffer {
    func drawLine(_ line: Line, width: Int, height: Int, color: Color24, algorithm: Line.Algorithm) async {
        await self.drawBresenham(line: line, width: width, height: height, color: color)
    }
    
    private func drawBresenham(line: Line, width: Int, height: Int, color: Color24) async {
        
        /* Algo lifted straight from wikipedia: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm */
        
        var x0 = Int(line.start.x * Double(width - 1))
        var y0 = Int(line.start.y * Double(height - 1))

        let x1 = Int(line.end.x * Double(width - 1))
        let y1 = Int(line.end.y * Double(height - 1))
        
        let dx = abs(x1 - x0)
        let sx = x0 < x1 ? 1 : -1
        let dy = -abs(y1 - y0)
        let sy = y0 < y1 ? 1 : -1
        var error = dx + dy
        while true {
            await self.plotPixel(x0, y0, color: color)
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * error
            if e2 >= dy {
                if x0 == x1 { break }
                error = error + dy
                x0 = x0 + sx
            }
            if e2 <= dx {
                if y0 == y1 { break }
                error = error + dx
                y0 = y0 + sy
            }
        }
    }
}
