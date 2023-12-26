
import Foundation

public protocol Sensor<T>: AnyObject, Identifiable {
    associatedtype T: SensorOutput
    var id: String { get }
    var location: SensorLocation { get }
    var outputType: SensorOutputType { get }
    var readings: AsyncStream<Result<Reading<T>, Error>> { get }
    var erasedToAnySensor: AnySensor<Self> { get }
}

extension Sensor {
    public var erasedToAnySensor: AnySensor<Self> {
        AnySensor(sensor: self)
    }
}

extension Sensor {
    var name: String {
        self.outputType.toString + "_" + self.location.toString + "_" + self.id
    }
}
