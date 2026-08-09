import Foundation

// MARK: - Difficulty

enum AIDifficulty: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case medium   = "Medium"
    case expert   = "Expert"

    var id: String { rawValue }

    /// Localized display name — `rawValue` stays a stable English identifier
    /// (used for storage/logic), this is what the UI shows.
    var displayName: String {
        switch self {
        case .beginner: return L("difficulty.beginner")
        case .medium:   return L("difficulty.medium")
        case .expert:   return L("difficulty.expert")
        }
    }

    var requiresPro: Bool {
        switch self {
        case .beginner: return false
        case .medium:   return true
        case .expert:   return true
        }
    }

    var depth: Int {
        switch self {
        case .beginner: return 3
        case .medium:   return 4
        case .expert:   return 4
        }
    }

    /// Chance (0-1) of picking a random move instead of the best one.
    var blunderChance: Double {
        switch self {
        case .beginner: return 0.25
        case .medium:   return 0.05
        case .expert:   return 0.0
        }
    }
}

// MARK: - AIEngine

class AIEngine {

    let difficulty: AIDifficulty
    let color: PieceColor

    /// Hashes of recent positions the AI has produced. Used to penalise moves
    /// that lead back to a recently-seen state, so the AI doesn't shuffle.
    private var recentHashes: [Int] = []
    private let recentHashLimit = 8

    init(difficulty: AIDifficulty, color: PieceColor = .cho) {
        self.difficulty = difficulty
        self.color = color
    }

    func bestMove(board: Board, completion: @escaping (Position, Position) -> Void) {
        let depth = difficulty.depth
        let aiColor = color
        let boardCopy = board
        let history = recentHashes

        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.search(board: boardCopy, depth: depth, color: aiColor, history: history)
            DispatchQueue.main.async { [weak self] in
                if let (from, to) = result {
                    var after = boardCopy
                    if from != to { after.movePiece(from: from, to: to) }
                    if let self {
                        self.recentHashes.append(self.boardHash(after))
                        if self.recentHashes.count > self.recentHashLimit {
                            self.recentHashes.removeFirst()
                        }
                    }
                    completion(from, to)
                }
            }
        }
    }

    /// Stable hash of a board's piece layout. Ignores piece UUIDs so equivalent
    /// positions hash to the same value (critical for repetition detection).
    private func boardHash(_ board: Board) -> Int {
        var entries = [(Int, PieceType, PieceColor)]()
        entries.reserveCapacity(board.pieces.count)
        for p in board.pieces {
            entries.append((p.position.y * 9 + p.position.x, p.type, p.color))
        }
        entries.sort { $0.0 < $1.0 }
        var hasher = Hasher()
        for (idx, type, color) in entries {
            hasher.combine(idx)
            hasher.combine(type)
            hasher.combine(color)
        }
        return hasher.finalize()
    }

    // MARK: - Search

    private func search(board: Board, depth: Int, color: PieceColor, history: [Int]) -> (Position, Position)? {
        var bestFrom: Position?
        var bestTo: Position?
        var bestScore = Int.min
        var alpha = Int.min
        let ordered = orderedMoves(for: color, on: board)
        var allMoves: [(Position, Position)] = []
        allMoves.reserveCapacity(ordered.count)

        for (from, to, _) in ordered {
            allMoves.append((from, to))
            var copy = board
            if from != to { copy.movePiece(from: from, to: to) } // from == to means "pass"
            var score = minimax(board: copy, depth: depth - 1,
                                alpha: alpha, beta: Int.max,
                                maximizing: false, aiColor: color)
            // Anti-shuffle: heavily penalise moves that revisit a recent position.
            // Big enough to override small positional ties, small enough not to
            // refuse a genuinely winning capture that happens to repeat.
            if history.contains(boardHash(copy)) {
                score -= 150
            }
            if score > bestScore {
                bestScore = score
                bestFrom = from
                bestTo = to
            }
            alpha = max(alpha, score)
        }

        // Beginner sometimes picks a random legal move instead of the best —
        // but never when a mate is in sight, so it actually finishes won games.
        if difficulty.blunderChance > 0,
           bestScore < 50_000,
           !allMoves.isEmpty,
           Double.random(in: 0..<1) < difficulty.blunderChance {
            let random = allMoves.randomElement()!
            return random
        }

        if let f = bestFrom, let t = bestTo { return (f, t) }
        return nil
    }

    private func minimax(board: Board, depth: Int,
                         alpha: Int, beta: Int,
                         maximizing: Bool, aiColor: PieceColor) -> Int {
        if depth == 0 {
            return evaluate(board: board, for: aiColor)
        }

        let currentColor = maximizing ? aiColor : aiColor.opposite
        var alpha = alpha
        var beta = beta
        var foundMove = false

        let ordered = orderedMoves(for: currentColor, on: board)

        if maximizing {
            var value = Int.min
            for (from, to, _) in ordered {
                foundMove = true
                var copy = board
                if from != to { copy.movePiece(from: from, to: to) }
                let score = minimax(board: copy, depth: depth - 1,
                                    alpha: alpha, beta: beta,
                                    maximizing: false, aiColor: aiColor)
                value = max(value, score)
                alpha = max(alpha, value)
                if alpha >= beta { return value }
            }
            if !foundMove {
                return board.isInCheck(color: currentColor) ? -100000 + depth : 0
            }
            return value
        } else {
            var value = Int.max
            for (from, to, _) in ordered {
                foundMove = true
                var copy = board
                if from != to { copy.movePiece(from: from, to: to) }
                let score = minimax(board: copy, depth: depth - 1,
                                    alpha: alpha, beta: beta,
                                    maximizing: true, aiColor: aiColor)
                value = min(value, score)
                beta = min(beta, value)
                if alpha >= beta { return value }
            }
            if !foundMove {
                return board.isInCheck(color: currentColor) ? 100000 - depth : 0
            }
            return value
        }
    }

    /// Generates all legal moves for a side, sorted with captures first
    /// (highest-value victim first), plus a "pass" candidate (encoded as
    /// from == to) whenever the side isn't in check — Janggi allows passing.
    /// Better move ordering => alpha-beta prunes far more aggressively, which
    /// is the difference between Expert taking 1 second vs 30+ seconds per move.
    private func orderedMoves(for color: PieceColor, on board: Board) -> [(Position, Position, Int)] {
        var moves: [(Position, Position, Int)] = []
        moves.reserveCapacity(48)
        for piece in board.pieces where piece.color == color {
            for dest in board.validMoves(for: piece) {
                let captureValue = board.piece(at: dest).map { $0.type.materialValue } ?? 0
                moves.append((piece.position, dest, captureValue))
            }
        }
        moves.sort { $0.2 > $1.2 }
        if !board.isInCheck(color: color), let king = board.general(for: color) {
            moves.append((king.position, king.position, 0)) // pass
        }
        return moves
    }

    // MARK: - Evaluation

    private func evaluate(board: Board, for color: PieceColor) -> Int {
        var score = 0
        var oppGeneral: Position?
        for piece in board.pieces {
            let v = piece.type.materialValue + positionBonus(piece)
            score += piece.color == color ? v : -v
            if piece.type == .general && piece.color != color {
                oppGeneral = piece.position
            }
        }

        // Endgame drive: when the AI is materially winning, reward closing in
        // on the enemy general and restricting its mobility. Without this, the
        // AI sees every move as equally good and shuffles instead of mating.
        if score >= 700, let king = oppGeneral {
            for piece in board.pieces where piece.color == color {
                switch piece.type {
                case .chariot, .cannon, .horse, .soldier, .elephant:
                    // Elephant included (unlike Xiangqi's) — it roams the whole
                    // board and can genuinely close in on the enemy general.
                    // Guard stays excluded — it can never leave its own palace.
                    let dist = abs(piece.position.x - king.x) + abs(piece.position.y - king.y)
                    score += max(0, 18 - dist) * 2
                default:
                    break
                }
            }
            if let kingPiece = board.general(for: color.opposite) {
                score -= board.validMoves(for: kingPiece).count * 15
            }
        }

        return score
    }

    /// Small positional bonus to encourage central / advanced placement.
    private func positionBonus(_ piece: Piece) -> Int {
        switch piece.type {
        case .soldier:
            // Janggi has no river, so reward advancement continuously by rank
            // rather than a one-time river-crossing bonus.
            let ranksAdvanced = piece.color == .han ? (6 - piece.position.y) : (piece.position.y - 3)
            return max(0, ranksAdvanced) * 15
        case .horse:
            // Prefer central positions
            let cx = abs(piece.position.x - 4)
            return max(0, 3 - cx) * 10
        case .chariot:
            // Rooks on open files are good — approximate with central bonus
            return max(0, 4 - abs(piece.position.x - 4)) * 5
        default:
            return 0
        }
    }
}
