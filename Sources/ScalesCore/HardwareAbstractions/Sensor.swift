
public protocol Sensor<T>: AnyObject {
    associatedtype T: SensorOutput
    var delegate: (any SensorDelegate<T>)? { get set }
    func start()
}

public protocol SensorOutput<T> {
    associatedtype T
    var stringValue: String { get }
}

public protocol SensorDelegate<T>: AnyObject {
    associatedtype T: SensorOutput
    func didGetReading(_ output: T)
}
