
import Foundation

public struct Reading<T: SensorOutput>: Codable {
    public let sensorID: String
    public let sensorLocation: SensorLocation
    public let outputType: ScalesCore.SensorOutputType
    public let value: T
    public init(outputType: ScalesCore.SensorOutputType, sensorLocation: SensorLocation, sensorID: String, value: T) {
        self.outputType = outputType
        self.sensorLocation = sensorLocation
        self.sensorID = sensorID
        self.value = value
    }
}
