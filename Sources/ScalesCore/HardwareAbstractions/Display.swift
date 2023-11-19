
public protocol Display {
    var resolution: Size { get }
    func showFrame(_ frameBuffer: FrameBuffer)
}
