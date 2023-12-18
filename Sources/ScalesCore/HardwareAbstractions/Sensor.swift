
import Foundation

public protocol Sensor<T>: AnyObject, Identifiable {
    associatedtype T: SensorOutput
    var name: String { get }
    var location: SensorLocation { get }
    var outputType: SensorOutputType { get }
    var readings: AsyncStream<T> { get }
    var erasedToAnySensor: AnySensor<Self> { get }
}

extension Sensor {
    public var erasedToAnySensor: AnySensor<Self> {
        AnySensor(sensor: self)
    }
}

public protocol SensorOutput: Sendable, Codable, Comparable {
    var stringValue: String { get }
}
