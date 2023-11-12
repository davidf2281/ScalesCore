
public enum GraphicsCommand {
    case drawText(DrawTextPayload)
    case drawLines(DrawLinesPayload)
}

protocol CommandPayload {}

public struct DrawTextPayload: CommandPayload {
    let string: String
    let point: Point
    let font: Font
    let color: Color24
}

public struct DrawLinesPayload: CommandPayload {
    
    let lines: [Line]
    let width: Double
    let color: Color24
    let algorithm: Line.Algorithm
    
    init(lines: [Line], width: Double, color: Color24, algorithm: Line.Algorithm = .bresenham) {
        self.lines = lines
        self.width = width
        self.color = color
        self.algorithm = algorithm
    }
}
