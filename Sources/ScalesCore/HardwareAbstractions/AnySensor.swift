
import Foundation

public final class AnySensor<S: Sensor>: Sensor {
    
    public var readings: AsyncStream<S.T> {
            return self.unerasedSensor.readings
            //            monitor.quakeHandler = { quake in
            //                continuation.yield(quake)
            //            }
            //            continuation.onTermination = { @Sendable _ in
            //                monitor.stopMonitoring()
            //            }
            //            monitor.startMonitoring()
    }
    
    public typealias T = S.T

    public var name: String {
        unerasedSensor.name
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
