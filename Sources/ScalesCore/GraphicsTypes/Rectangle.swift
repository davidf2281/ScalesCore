
public struct Rectangle {
    let bottomLeft: Point
    let topRight: Point
    var width: Double {
        abs(self.topRight.x - self.bottomLeft.x)
    }
    init(_ blX: Double, _ blY: Double, _ trX: Double, _ trY: Double) {
        self.bottomLeft = .init(blX, blY)
        self.self.topRight = .init(trX, trY)
    }
}
