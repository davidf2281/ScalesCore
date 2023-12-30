
import Foundation

public final class AnySensor<S: SensorOutput>: Sensor {
    
    public typealias T = S

    public var readings: AsyncStream<Result<[Reading<T>], Error>> {
        return self.unerasedSensor.readings
    }
        
    public var id: String {
        unerasedSensor.id
    }
    
    public var location: SensorLocation {
        unerasedSensor.location
    }
    
    private let unerasedSensor: any Sensor<T>
    
    init(sensor: any Sensor<T>) {
        self.unerasedSensor = sensor
    }
}
