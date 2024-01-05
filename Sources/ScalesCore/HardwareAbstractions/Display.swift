
public protocol Display {
    var resolution: Size { get }
    var aspect: Aspect { get }
    func showFrame(_ frameBuffer: FrameBuffer) async throws
}

public enum Aspect {
    case portrait
    case landscape
}
