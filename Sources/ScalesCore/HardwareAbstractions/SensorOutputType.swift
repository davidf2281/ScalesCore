
import Foundation

public enum SensorOutputType: Codable {
    
    case temperature(unit: TemperatureUnit)
    case barometricPressure(unit: PressureUnit)
    case humidity(unit: HumidityUnit)
    
    public enum TemperatureUnit: String, Codable {
        case celsius
    }

    public enum PressureUnit: String, Codable {
        case hPa
    }
    
    public enum HumidityUnit: String, Codable {
        case rhd
    }
    
    public var toString: String {
        switch self {
            case .temperature(unit: let unit):
                return "temperature-" + unit.rawValue
            case .barometricPressure(unit: let unit):
                return "pressure-" + unit.rawValue
            case .humidity(unit: let unit):
                return "humidity-" + unit.rawValue
        }
    }
}
