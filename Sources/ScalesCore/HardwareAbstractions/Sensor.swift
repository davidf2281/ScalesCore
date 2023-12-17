
import Foundation

public protocol Sensor<T>: AnyObject, Identifiable {
    associatedtype T: SensorOutput
    var name: String { get }
    var location: SensorLocation { get }
    var outputType: SensorOutputType { get }
    var delegate: (any SensorDelegate)? { get set }
    func start(minUpdateInterval: TimeInterval)
    var erasedToAnySensor: AnySensor<Self> { get }
    var readings: AsyncStream<T> { get }
}

extension Sensor {
    public var erasedToAnySensor: AnySensor<Self> {
        AnySensor(sensor: self)
    }
}

public protocol SensorDelegate: AnyObject {
    func didGetReading<T>(_ reading: T, sender: any Sensor<T>) async
}

public protocol SensorOutput: Sendable, Codable, Comparable {
    var stringValue: String { get }
}
