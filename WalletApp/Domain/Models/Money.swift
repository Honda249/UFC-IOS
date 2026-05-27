import Foundation

/// SAR monetary values — always `Decimal`, never floating point.
struct Money: Sendable, Equatable {
    let amount: Decimal
    let currencyCode: String

    init(amount: Decimal, currencyCode: String = "SAR") {
        self.amount = amount
        self.currencyCode = currencyCode
    }
}

extension NumberFormatter {
    static let sar: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "SAR"
        formatter.locale = Locale(identifier: "ar_SA")
        return formatter
    }()
}
