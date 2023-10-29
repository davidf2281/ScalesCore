
import Foundation

public protocol SensorDelegate {
    func didGetReading(_ reading: Float)
}

public protocol Sensor: AnyObject {
    var delegate: SensorDelegate? { get set }
    func start()
}

public protocol Display {
    func render(commands: [GraphicsContext.Command])
}

public class GraphicsContext {
    
    private var commandQueue: [Command] = []
    private let display: Display
    
    init(display: Display) {
        self.display = display
    }
    
    public enum Command {
        case drawText(DrawTextPayload)
        case drawLines(DrawLinesPayload)
    }
    
    func queueCommand(_ command: Command) {
        self.commandQueue.append(command)
    }
    
    func flush() {
        self.display.render(commands: self.commandQueue)
    }
}

public protocol FrameBuffer {
    init(width: Int, height: Int)
    func plotPoint(x: Int, y: Int, color: Color24)
}

protocol CommandPayload {}

public struct DrawTextPayload: CommandPayload {
    let string: String
    let point: CGPoint
    let font: Font
}

public struct DrawLinesPayload: CommandPayload {
    let lines: [Line]
    let width: CGFloat
    let color: Color24
}

public struct Line {
    let start: CGPoint
    let end: CGPoint
}

public struct Color24 {
    let red: Int8
    let green: Int8
    let blue: Int8
}

public struct Font {
    static var system: Font {
        return Self()
    }
}

extension CGPoint {
    static var zero: CGPoint {
        return Self(x: 0, y: 0)
    }
}
