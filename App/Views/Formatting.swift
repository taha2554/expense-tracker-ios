import Foundation

enum Money {
    /// Currency code from Settings, defaulting to the device's currency.
    static var currencyCode: String {
        UserDefaults.standard.string(forKey: "currencyCode") ?? Locale.current.currency?.identifier ?? "TRY"
    }

    static func format(_ value: Decimal) -> String {
        value.formatted(.currency(code: currencyCode))
    }
}
