import Foundation

extension Locale {
  var bcp47Tag: String {
    identifier(.bcp47).lowercased()
  }
}
