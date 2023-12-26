
public protocol SensorOutput: Sendable, Codable, FloatingPoint {
    var stringValue: String { get }
    var floatValue: Float { get }
}
