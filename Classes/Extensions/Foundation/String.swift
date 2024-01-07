import Foundation

extension Optional where Wrapped == String {
    var isEmpty: Bool {
        switch self {
        case .some(let theString): theString.isEmpty
        case .none: true
        }
    }
}
