
import Foundation

public struct Color24 {
    
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    
    public static var black: Self {
        Self.init(red: 0, green: 0, blue: 0)
    }
    
    public static var white: Self {
        Self.init(red: 255, green: 255, blue: 255)
    }
}
