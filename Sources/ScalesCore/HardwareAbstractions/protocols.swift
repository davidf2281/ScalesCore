
import Foundation

public protocol SensorDelegate {
    func didGetReading(_ reading: Float)
}

public protocol Sensor: AnyObject {
    var delegate: SensorDelegate? { get set }
    func start()
}

public protocol Display {
    var width: Int { get }
    var height: Int { get }
    func showFrame(_ frameBuffer: FrameBuffer)
}
