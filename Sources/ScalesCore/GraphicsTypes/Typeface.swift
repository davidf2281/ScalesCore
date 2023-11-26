
public struct Font {
    let size: Double
    private let typeFace: Typeface
    
    enum TypefaceName {
        case system
    }
    
    init(_ typeFaceName: TypefaceName, size: Double) {
        self.size = size
        switch typeFaceName {
            case .system:
                self.typeFace = System()
        }
    }
    
    func linesForString(_ string: String) -> [Line]? {
        self.typeFace.linesForString(string, size: self.size)
    }
}

public protocol Typeface {
    func linesForString(_ string: String, size: Double) -> [Line]?
}

public struct System: Typeface {
 
    // All glyphs have line coords based on a 4 x 5 grid.
    // We normalize by scaling down to fit the y-height (ie max y height is 1.0)
    static let scaleToNormalize: Double = 1.0 / 5.0
    
    public func linesForString(_ string: String, size: Double) -> [Line]? {
        
        var allLines: [Line] = []
        var previousGlyph: Glyph? = nil
        var offsetAccumulator: Double = 0
        for character in string {
            
            let offset: Double
            
            if let previousGlyph {
                offset = previousGlyph.boundingBox.width
            } else {
                offset = 0
            }
            
            offsetAccumulator += offset + 1
            
            guard let glyph = character.glyphName?.glyph else {
                continue
            }
            
            let lines = glyph.lines.offset(by: .init(offsetAccumulator, 0))
            
            allLines += lines
            
            previousGlyph = glyph
        }
        
        // TODO: Optimize this double-scaling out
        return allLines
            .scaled(by: Self.scaleToNormalize)
            .scaled(by: size)
    }
    
    struct Glyph {
        let name: GlyphName
        let lines: [Line]
        
        init(name: GlyphName, lines: [Line]) {
            self.name = name
            self.lines = lines
        }
        
        var boundingBox: Rectangle {
            let xValues = lines.flatMap { [$0.start.x, $0.end.x] }
            let yValues = lines.flatMap { [$0.start.y, $0.end.y] }
            return .init(xValues.min, yValues.min, xValues.max, yValues.max)
        }
    }
    
    enum GlyphName {
        
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
        case dot
        
        fileprivate var glyph: Glyph {
            switch self {
                case .zero:
                        .init(name: self,
                              lines: [Line(0, 5, 4, 5),
                                      Line(4, 5, 4, 0),
                                      Line(4, 0, 0, 0),
                                      Line(0, 0, 0, 5),
                                      Line(0, 0, 4, 5)])
                    
                case .one:
                        .init(name: self,
                              lines: [Line(1, 0, 3, 0),
                                      Line(2, 0, 2, 5),
                                      Line(2, 5, 1, 4)])
                    
                    
                case .two:
                        .init(name: self,
                              lines: [Line(0, 4, 0, 5),
                                      Line(0, 5, 4, 5),
                                      Line(4, 5, 4, 4),
                                      Line(4, 4, 0, 1),
                                      Line(0, 1, 0, 0),
                                      Line(0, 0, 4, 0),
                                      Line(4, 0, 4, 1)])
                    
                case .three:
                        .init(name: self,
                              lines:  [Line(0, 4, 0, 5),
                                       Line(0, 5, 4, 5),
                                       Line(4, 5, 4, 4),
                                       Line(4, 4, 2, 3),
                                       Line(2, 3, 4, 2),
                                       Line(4, 2, 4, 0),
                                       Line(4, 0, 0, 0),
                                       Line(0, 0, 0, 1)])
                    
                case .four:
                        .init(name: self,
                              lines:  [Line(3, 5, 0, 2),
                                       Line(0, 2, 4, 2),
                                       Line(2, 2.5, 2, 0)])
                    
                case .five:
                        .init(name: self,
                              lines:   [Line(4, 4, 4, 5),
                                        Line(4, 5, 0, 5),
                                        Line(0, 5, 0, 2.5),
                                        Line(0, 2.5, 4, 2.5),
                                        Line(4, 2.5, 4, 0),
                                        Line(4, 0, 0, 0),
                                        Line(0, 0, 0, 1)])
                    
                case .six:
                        .init(name: self,
                              lines:    [Line(4, 4, 4, 5),
                                         Line(4, 5, 0, 5),
                                         Line(0, 5, 0, 0),
                                         Line(0, 0, 4, 0),
                                         Line(4, 0, 4, 2.5),
                                         Line(4, 2.5, 0, 2.5)])
                    
                case .seven:
                        .init(name: self,
                              lines:    [Line(0, 4, 0, 5),
                                         Line(0, 5, 4, 5),
                                         Line(4, 5, 4, 3.5),
                                         Line(4, 3.5, 0, 0)])
                    
                case .eight:
                        .init(name: self,
                              lines:   [Line(0.5, 5, 3.5, 5),
                                        Line(3.5, 5, 4, 4.5),
                                        Line(4, 4.5, 4, 3),
                                        Line(4, 3, 3, 2.5),
                                        Line(3, 2.5, 0.5, 2.5),
                                        Line(0.5, 2.5, 0, 2),
                                        Line(0, 2, 0, 0.5),
                                        Line(0, 0.5, 0.5, 0),
                                        Line(0.5, 0, 3.5, 0),
                                        Line(3.5, 0, 4, 0.5),
                                        Line(4, 0.5, 4, 2),
                                        Line(4, 2, 3, 2.5),
                                        Line(0.5, 5, 0, 4.5),
                                        Line(0, 4.5, 0, 3),
                                        Line(0, 3, 0.25, 2.5)])
                    
                case .nine:
                        .init(name: self,
                              lines:   [Line(0, 5, 4, 5),
                                        Line(4, 5, 4, 0),
                                        Line(4, 2.5, 0, 2.5),
                                        Line(0, 2.5, 0, 5)])
                    
                case .dot:
                        .init(name: self,
                              lines:   [Line(0, 0, 0.5, 0),
                                        Line(0.5, 0, 0.5, 0.5),
                                        Line(0.5, 0.5, 0, 0.5),
                                        Line(0, 0.5, 0, 0)])
            }
        }
    }
}

extension Array where Element == Double {
    var min: Double {
        return self.reduce(Double.infinity) { previous, next in
            return next < previous ? next : previous
        }
    }
    
    var max: Double {
        return self.reduce(-Double.infinity) { previous, next in
            return next > previous ? next : previous
        }
    }
}

extension Array where Element == Line {
    func offset(by offset: Point) -> Self {
        self.map {
            Line($0.start.x + offset.x, $0.start.y + offset.y, $0.end.x + offset.x, $0.end.y + offset.y)
        }
    }
    
    func scaled(by scale: Double) -> Self {
        self.map {
            Line($0.start.x * scale, $0.start.y * scale, $0.end.x * scale, $0.end.y * scale)
        }
    }
}

extension Character {
    
    var glyphName: System.GlyphName? {
        switch self {
            case "0":
                return .zero
            case "1":
                return .one
            case "2":
                return .two
            case "3":
                return .three
            case "4":
                return .four
            case "5":
                return .five
            case "6":
                return .six
            case "7":
                return .seven
            case "8":
                return .eight
            case "9":
                return .nine
            case ".":
                return .dot
                
            default:
                return nil
        }
    }
}
