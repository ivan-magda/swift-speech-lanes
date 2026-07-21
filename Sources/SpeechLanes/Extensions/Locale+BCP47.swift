import Foundation

extension Locale {
    /// A normalized, case-folded BCP-47 tag used to compare locales for identity. `Locale`'s own
    /// `==` compares far more than the language tag, so lane resolution keys off this instead.
    var bcp47Tag: String {
        identifier(.bcp47).lowercased()
    }
}
