
import Foundation

public struct Line {
    let start: CGPoint
    let end: CGPoint
    
    enum Algorithm {
        case naive
        case bresenham
    }
}