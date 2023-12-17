
import Foundation

public class AnySensor<S: SensorOutput>: Sensor, SensorDelegate {
 
    public var delegate: (any SensorDelegate<S>)?
    
    public typealias T = S
    
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
        
    private let unerasedSensor: any Sensor<S>
    
    init(sensor: any Sensor<S>) {
        self.unerasedSensor = sensor
        sensor.delegate = self
    }

    public func didGetReading(_ output: S) async {
        await self.delegate?.didGetReading(output)
    }
}
