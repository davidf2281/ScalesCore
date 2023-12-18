
import Foundation

public final class AnySensor<S: Sensor>: Sensor, SensorDelegate {
    
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

    public var delegate: (any SensorDelegate)?
    
    public typealias T = S.T
    
    public func start(minUpdateInterval: TimeInterval) {
        self.unerasedSensor.start(minUpdateInterval: minUpdateInterval)
    }
    
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
        sensor.delegate = self
    }

    public func didGetReading<T>(_ reading: T, sender: any Sensor<T>) async {
//        await self.delegate?.didGetReading(reading, sender: self)
    }
}
