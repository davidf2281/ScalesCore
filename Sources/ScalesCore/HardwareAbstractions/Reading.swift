
import Foundation

public struct Reading<T: SensorOutput>: Codable {
    public let outputType: ScalesCore.SensorOutputType
    public let value: T
    public init(outputType: ScalesCore.SensorOutputType, value: T) {
        self.outputType = outputType
        self.value = value
    }
}
