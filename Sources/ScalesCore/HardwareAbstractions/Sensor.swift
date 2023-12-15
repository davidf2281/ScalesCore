
public protocol Sensor<T>: SensorRepresentable, AnyObject, Identifiable {
    associatedtype T: SensorOutput
    var delegate: (any SensorDelegate<T>)? { get set }
    func start()
}

public protocol SensorRepresentable {
    var name: String { get }
    var location: SensorLocation { get }
    var outputType: SensorOutputType { get }
}

public enum TemperatureUnit: String, Codable {
    case celsius
}

public enum PressureUnit: String, Codable {
    case hPa
}

public enum HumidityUnit: String, Codable {
    case rhd
}

public enum SensorLocation: Codable {
    case indoor(location: Location?)
    case outdoor(location: Location?)
}

public struct Location: Codable {
    let latitude: Double
    let longitude: Double
}

public enum SensorOutputType: Codable {
    case temperature(unit: TemperatureUnit)
    case barometricPressure(unit: PressureUnit)
    case humidity(unit: HumidityUnit)
}

public protocol SensorOutput: Sendable, Codable, Comparable {
    var stringValue: String { get }
}

public protocol SensorDelegate<T>: AnyObject {
    associatedtype T: SensorOutput
    func didGetReading(_ output: T) async
}
