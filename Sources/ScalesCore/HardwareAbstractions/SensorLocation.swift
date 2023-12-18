
import Foundation

public enum SensorLocation: Codable {
    case indoor(location: Location?)
    case outdoor(location: Location?)
    
    public struct Location: Codable {
        let latitude: Double
        let longitude: Double
        
        var toString: String {
            "lat-\(latitude)long-\(longitude)"
        }
    }
    
    public var toString: String {
        switch self {
            case .indoor(location: let location):
                "Indoor" + (location?.toString ?? "")
            case .outdoor(location: let location):
                "Outdoor" + (location?.toString ?? "")
        }
    }
}

