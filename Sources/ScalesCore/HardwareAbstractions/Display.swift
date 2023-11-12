
public protocol Display {
    var width: Int { get }
    var height: Int { get }
    func showFrame(_ frameBuffer: FrameBuffer)
}
