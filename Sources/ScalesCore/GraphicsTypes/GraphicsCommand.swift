
import Foundation

public enum GraphicsCommand {
    case drawText(DrawTextPayload)
    case drawLines(DrawLinesPayload)
}

public struct DrawTextPayload: CommandPayload {
    let string: String
    let point: CGPoint
    let font: Font
    let color: Color24
}

protocol CommandPayload {}

public struct DrawLinesPayload: CommandPayload {
    let lines: [Line]
    let width: CGFloat
    let color: Color24
}
