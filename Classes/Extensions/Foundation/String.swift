import Foundation

extension Optional where Wrapped == String {
    var isEmpty: Bool {
        switch self {
        case .some(let theString): theString.isEmpty
        case .none: true
        }
    }
}

extension String {
    // I tried to use attributed / markdown to do this automatically and it didn't work, and I
    // don't know why: the code compiles, but the result is always the singular
    func pluralized(count: Int) -> String {
        String(count) + " " + self + (count == 1 ? "" : "s")
    }
}
