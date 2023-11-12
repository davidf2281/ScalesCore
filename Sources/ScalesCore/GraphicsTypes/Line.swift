
public struct Line {
    let start: Point
    let end: Point
    
    init(_ startX: Double, _ startY: Double, _ endX: Double, _ endY: Double) {
        self.start = .init(startX, startY)
        self.end = .init(endX, endY)
    }
    
    enum Algorithm {
        case naive
        case bresenham
    }
}
