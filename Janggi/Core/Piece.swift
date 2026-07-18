import Foundation

// MARK: - Position

/// A point on the 9×10 Janggi board (pieces sit on line intersections, not squares).
struct Position: Equatable, Hashable {
    let x: Int // column 0-8
    let y: Int // row 0-9

    /// Whether this position is within the board bounds.
    var isValid: Bool {
        x >= 0 && x <= 8 && y >= 0 && y <= 9
    }

    /// Whether this position is inside the Cho palace (cols 3–5, rows 0–2).
    var isInChoPalace: Bool {
        x >= 3 && x <= 5 && y >= 0 && y <= 2
    }

    /// Whether this position is inside the Han palace (cols 3–5, rows 7–9).
    var isInHanPalace: Bool {
        x >= 3 && x <= 5 && y >= 7 && y <= 9
    }
}

// MARK: - PieceColor

/// The two sides in Janggi. Cho (blue) moves first.
enum PieceColor: Equatable, Hashable {
    case han
    case cho

    /// The opponent's color.
    var opposite: PieceColor {
        self == .han ? .cho : .han
    }

    /// The forward direction for this color (Han moves up / decreasing y, Cho moves down / increasing y).
    var forwardDelta: Int {
        self == .han ? -1 : 1
    }
}

// MARK: - PieceType

/// The seven piece types in Janggi. Most pieces share the same hanja for both
/// sides (distinguished by ink color); General and Soldier use distinct characters
/// per side, same convention as Xiangqi's General/Soldier.
enum PieceType: Equatable, Hashable {
    case general    // 漢/楚 — the king (Gung)
    case guardian   // 士 — Sa, moves like the General within the palace
    case elephant   // 象 — Sang, 1 orthogonal + 2 diagonal "stretched" leap
    case horse      // 馬 — Ma, L-shape, can be blocked
    case chariot    // 車 — Cha, moves any distance orthogonally
    case cannon     // 包 — Po, must jump exactly one non-cannon screen to move or capture
    case soldier    // 兵/卒 — Byeong (Han) / Jol (Cho), forward or sideways, never backward

    /// Display hanja for the given color.
    func displayCharacter(for color: PieceColor) -> String {
        switch self {
        case .general:  return color == .han ? "漢" : "楚"
        case .guardian: return "士"
        case .elephant: return "象"
        case .horse:    return "馬"
        case .chariot:  return "車"
        case .cannon:   return "包"
        case .soldier:  return color == .han ? "兵" : "卒"
        }
    }

    /// Official Janggi material value, scaled ×100 for integer scoring
    /// (Chariot 13 / Cannon 7 / Horse 5 / Elephant 3 / Guard 3 / Soldier 2).
    /// Single source of truth — shared by AIEngine's evaluation and GameModel's
    /// DEBUG self-play heuristic, so the two never drift out of sync.
    var materialValue: Int {
        switch self {
        case .general:  return 10000
        case .chariot:  return 1300
        case .cannon:   return 700
        case .horse:    return 500
        case .elephant: return 300
        case .guardian: return 300
        case .soldier:  return 200
        }
    }
}

// MARK: - Piece

/// A Janggi piece on the board.
struct Piece: Equatable, Hashable, Identifiable {
    let id: UUID
    let type: PieceType
    let color: PieceColor
    var position: Position

    /// The hanja character for display.
    var displayCharacter: String {
        type.displayCharacter(for: color)
    }

    init(type: PieceType, color: PieceColor, position: Position) {
        self.id = UUID()
        self.type = type
        self.color = color
        self.position = position
    }
}
