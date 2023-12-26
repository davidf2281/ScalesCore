
import Foundation

public final class AnySensor<S: Sensor>: Sensor {
    
    public typealias T = S.T

    public var readings: AsyncStream<Result<Reading<S.T>, Error>> {
        return self.unerasedSensor.readings
    }
        
    public var id: String {
        unerasedSensor.id
    }
    
    public var location: SensorLocation {
        unerasedSensor.location
    }
    
    public var outputType: SensorOutputType {
        unerasedSensor.outputType
    }
    
    private let unerasedSensor: any Sensor<S.T>
    
    init(sensor: any Sensor<S.T>) {
        self.unerasedSensor = sensor
    }
}
