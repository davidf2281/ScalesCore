
import Foundation

public protocol Sensor<T>: AnyObject, Identifiable {
    associatedtype T: SensorOutput
    var id: String { get }
    var location: SensorLocation { get }
    var readings: AsyncStream<Result<[Reading<T>], Error>> { get }
    var erasedToAnySensor: AnySensor<Self.T> { get }
}

extension Sensor {
    public var erasedToAnySensor: AnySensor<Self.T> {
        AnySensor(sensor: self)
    }
}

extension Sensor {
    var name: String {
        self.location.toString + "_" + self.id
    }
}
