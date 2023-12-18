
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
    
    var toString: String {
        switch self {
            case .temperature(unit: let unit):
                return "Temperature-" + unit.rawValue
            case .barometricPressure(unit: let unit):
                return "Pressure-" + unit.rawValue
            case .humidity(unit: let unit):
                return "Humidity-" + unit.rawValue
        }
    }
}
