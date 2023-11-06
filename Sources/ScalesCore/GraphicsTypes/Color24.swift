
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
    
    public var packed565: UInt16 {
        let red5 =   UInt16(self.red   & 0b11111000)
        let green6 = UInt16(self.green & 0b11111100) >> 5
        let blue5 =  UInt16(self.blue  & 0b11111000) >> 11
        return red5 | green6 | blue5
    }
}
