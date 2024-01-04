
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
    
    public static var gray: Self {
        Self.init(red: 128, green: 128, blue: 128)
    }
    
    public static var red: Self {
        Self.init(red: 255, green: 0, blue: 0)
    }
    
    public static var green: Self {
        Self.init(red: 0, green: 255, blue: 0)
    }
    
    public static var blue: Self {
        Self.init(red: 0, green: 0, blue: 255)
    }
    
    public static var yellow: Self {
        Self.init(red: 128, green: 128, blue: 0)
    }
    
    public var packed565: UInt16 {
        let red5 =   UInt16(self.red   & 0b11111000) << 8
        let green6 = UInt16(self.green & 0b11111100) << 3
        let blue5 =  UInt16(self.blue  & 0b11111000) >> 3
        return red5 | green6 | blue5
    }
}
