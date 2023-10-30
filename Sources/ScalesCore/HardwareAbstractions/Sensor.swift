
import Foundation

public protocol Sensor: AnyObject {
    var delegate: SensorDelegate? { get set }
    func start()
}

public protocol SensorDelegate: AnyObject {
    func didGetReading(_ reading: Float)
}
