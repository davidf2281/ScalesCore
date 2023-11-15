
public protocol Display {
    var width: Int { get }
    var height: Int { get }
    static var supportedResolutions: [ScreenResolution] { get }
    func showFrame(_ frameBuffer: FrameBuffer)
}

public enum ScreenResolution {
    case w320h240
    case w240h320
    
    var size: ScalesCore.Size {
        switch self {
            case .w320h240:
                Size(width: 320, height: 240)
            case .w240h320:
                Size(width: 240, height: 320)
        }
    }
}
