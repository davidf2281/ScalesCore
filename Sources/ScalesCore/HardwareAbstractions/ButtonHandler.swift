
import Foundation

public protocol ButtonHandler {
    var buttonPresses: AsyncStream<ButtonPress>  { get }
}

public struct ButtonPress {
    public init(){}
}
