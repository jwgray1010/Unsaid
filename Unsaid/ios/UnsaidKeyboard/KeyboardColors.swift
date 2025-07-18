#if canImport(UIKit)
import UIKit
import Foundation
import NaturalLanguage
// MARK: – UIColor Extensions

extension UIColor {
    /// Rose/pink color for keyboard theme
    static let keyboardRose = UIColor(red: 0.9, green: 0.7, blue: 0.8, alpha: 1.0)

    /// Darker rose for pressed states
    static let keyboardRoseDark = UIColor(red: 0.8, green: 0.6, blue: 0.7, alpha: 1.0)

    /// Light rose for backgrounds
    static let keyboardRoseLight = UIColor(red: 0.95, green: 0.85, blue: 0.9, alpha: 1.0)

    /// Key background color - iPhone style white keys
    static let keyBackground = UIColor.white

    /// Key text color - iPhone style black text
    static let keyText = UIColor.black

    /// Keyboard background color - iPhone style light gray
    static let keyboardBackground = UIColor(red: 0.82, green: 0.84, blue: 0.87, alpha: 1.0)
    
    /// Special key background color - iPhone style darker gray for 123, return, backspace
    static let specialKeyBackground = UIColor(red: 0.68, green: 0.70, blue: 0.73, alpha: 1.0)
}
#endif