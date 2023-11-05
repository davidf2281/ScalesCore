
import Foundation

public struct Color24 {
    
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    
    public static var black: Self {
        Self.init(red: 0, green: 0, blue: 0)
    }
    
    public static var white: Self {
        Self.init(red: 255, green: 255, blue: 255)
    }
}
