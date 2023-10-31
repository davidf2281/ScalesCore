
import Foundation

public class FrameBuffer {
    
    let width: Int
    let height: Int
    private let pixelCount: Int
    public private(set) var pixels: [Color24]
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.pixelCount = width * height
        self.pixels = Array(repeating: .black, count: self.pixelCount)
    }
    
    func plotPixel(_ x: Int, _ y: Int, color: Color24) {
        pixels[index(for: x, y)] = color
    }
    
    func pixel(at x: Int, _ y: Int) -> Color24 {
        return pixels[index(for: x, y)]
    }
    
    private func index(for x: Int, _ y: Int) -> Int {
        return width * y + x
    }
}
