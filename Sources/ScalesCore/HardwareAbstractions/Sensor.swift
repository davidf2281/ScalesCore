
public protocol Sensor<T>: AnyObject, Codable {
    associatedtype T: SensorOutput, Comparable
    var outputType: SensorOutputType { get }
    var location: SensorLocation { get }
    var delegate: (any SensorDelegate<T>)? { get set }
    func start()
}

public enum TemperatureUnit: String {
    case celsius
}

public enum PressureUnit: String {
    case hPa
}

public enum HumidityUnit: String {
    case rhd
}

public enum SensorLocation {
    case indoor(location: Location?)
    case outdoor(location: Location?)
}

public struct Location {
    let latitude: Double
    let longitude: Double
}

public enum SensorOutputType {
    case temperature(unit: TemperatureUnit)
    case barometricPressure(unit: PressureUnit)
    case humidity(unit: HumidityUnit)
}

public protocol SensorOutput<T>: Sendable, Codable {
    associatedtype T: Codable
    
    var stringValue: String { get }
}

public protocol SensorDelegate<T>: AnyObject {
    associatedtype T: SensorOutput
    func didGetReading(_ output: T) async
}
