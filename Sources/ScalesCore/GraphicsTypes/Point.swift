
struct Point {
    let x: Double
    let y: Double
    
    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

extension Point {
    static var zero: Point {
        return Self(0, 0)
    }
}
