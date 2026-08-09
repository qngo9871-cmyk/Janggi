import Foundation

/// Looks up `key` in `Localizable.strings` (en.lproj / ko.lproj) and formats it
/// with any provided arguments. Every user-facing string in the app should go
/// through this — no bare English literals in Views for anything the player
/// actually reads (onboarding, buttons, game status, purchase flow).
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    guard !args.isEmpty else { return format }
    return String(format: format, arguments: args)
}
