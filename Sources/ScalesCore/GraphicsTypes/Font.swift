
public struct Font {
    static var system: Font {
        return Self()
    }
    
    enum glyph {
        
        case zero
        case one
        case two
        case three
        case four
        case five
        case six
        case seven
        case eight
        case nine
        
        func lines() -> [Line] {
            switch self {
                case .zero:
                    [
                        Line(0, 0, 1, 0),
                        Line(1, 0, 1, 1),
                        Line(1, 1, 0, 1),
                        Line(0, 1, 0, 0),
                        Line(0, 0, 1, 1)
                    ]
                case .one:
                    [
                        Line(0.375, 0, 0.375, 1),
                        Line(0.370, 0, 0.380, 0),
                        Line(0.375, 1.0, 0.370, 0.95)
                    ]
                case .two:
                    []
                case .three:
                    []
                case .four:
                    []
                case .five:
                    []
                case .six:
                    []
                case .seven:
                    []
                case .eight:
                    []
                case .nine:
                    []
            }
        }
    }
}
