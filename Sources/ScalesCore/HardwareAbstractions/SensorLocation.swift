
import Foundation

public enum SensorLocation: Codable {
    case indoor(location: Location?)
    case outdoor(location: Location?)
    
    public struct Location: Codable {
        let latitude: Double
        let longitude: Double
    }
}

