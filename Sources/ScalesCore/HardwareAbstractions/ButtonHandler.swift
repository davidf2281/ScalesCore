
import Foundation

protocol ButtonHandler {
    var buttonPresses: AsyncStream<ButtonPress>  { get }
}

struct ButtonPress {
    
}
