import SwiftUI

enum Theme {
    static let bg      = Color(red: 0.937, green: 0.957, blue: 0.988)   // #EFF4FC
    static let card    = Color.white
    static let ink     = Color(red: 0.06, green: 0.12, blue: 0.24)
    static let sub     = Color(red: 0.42, green: 0.49, blue: 0.60)
    static let line    = Color(red: 0.90, green: 0.93, blue: 0.97)
    static let blue    = Color(red: 0.18, green: 0.42, blue: 1.0)
    static let blueSoft = Color(red: 0.53, green: 0.72, blue: 1.0)
    static let grad = LinearGradient(colors: [blueSoft, blue], startPoint: .leading, endPoint: .trailing)
}
