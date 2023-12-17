
import Foundation

public protocol Sensor<T>: AnyObject, Identifiable {
    associatedtype T: SensorOutput
    var name: String { get }
    var location: SensorLocation { get }
    var outputType: SensorOutputType { get }
    var delegate: (any SensorDelegate<T>)? { get set }
    func start(minUpdateInterval: TimeInterval)
    var erasedToAnySensor: AnySensor<Self.T> { get }
}

extension Sensor {
    public var erasedToAnySensor: AnySensor<Self.T> {
        AnySensor(sensor: self)
    }
}

public protocol SensorDelegate<T>: AnyObject {
    associatedtype T: SensorOutput
    func didGetReading(_ output: T) async
}

public protocol SensorOutput: Sendable, Codable, Comparable {
    var stringValue: String { get }
}
