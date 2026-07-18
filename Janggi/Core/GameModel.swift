import Foundation

// MARK: - Game State

/// The high-level state of a game. Janggi has no stalemate: passing is always
/// legal when not in check, so "no legal move and not in check" never arises.
enum GameState: Equatable {
    case playing      // normal play
    case check        // current player's General is in check
    case checkmate    // current player is checkmated — they lose
}

// MARK: - GameModel

/// Observable game model that drives the UI.
/// Cho always moves first.
class GameModel: ObservableObject {

    // MARK: Published state

    @Published var board: Board
    @Published var currentTurn: PieceColor = .cho
    @Published var gameState: GameState = .playing
    @Published var selectedPiece: Piece?
    @Published var validMovesForSelected: [Position] = []
    @Published var winner: PieceColor?

    // MARK: Init

    init() {
        board = Board()
    }

    // MARK: - Selection & movement

    /// Called when the user taps a board position.
    func tap(at position: Position) {
        // Game is over — ignore taps.
        guard gameState == .playing || gameState == .check else { return }

        if let selected = selectedPiece {
            // A piece is already selected.
            if validMovesForSelected.contains(position) {
                // Execute the move.
                executeMove(from: selected.position, to: position)
            } else if let tapped = board.piece(at: position), tapped.color == currentTurn {
                // Tapped a different friendly piece — reselect.
                select(piece: tapped)
            } else {
                // Tapped an invalid square — deselect.
                deselect()
            }
        } else {
            // Nothing selected yet.
            if let tapped = board.piece(at: position), tapped.color == currentTurn {
                select(piece: tapped)
            }
        }
    }

    /// Select a piece and compute its valid moves.
    private func select(piece: Piece) {
        selectedPiece = piece
        validMovesForSelected = board.validMoves(for: piece)
    }

    /// Clear selection.
    private func deselect() {
        selectedPiece = nil
        validMovesForSelected = []
    }

    /// Execute a move, switch turns, and re-evaluate the game state.
    func executeMove(from origin: Position, to destination: Position) {
        board.movePiece(from: origin, to: destination)
        deselect()
        switchTurn()
        updateGameState()
    }

    /// Pass the turn without moving — legal in Janggi whenever not in check.
    func pass() {
        guard gameState == .playing else { return }
        deselect()
        switchTurn()
        updateGameState()
    }

    /// Switch to the other player's turn.
    private func switchTurn() {
        currentTurn = currentTurn.opposite
    }

    // MARK: - Game state evaluation

    /// Called after every move to check for check / checkmate. Since passing is
    /// always legal when not in check, "no legal move" only ever matters while
    /// in check — that's checkmate. Otherwise the game just continues.
    private func updateGameState() {
        let inCheck = board.isInCheck(color: currentTurn)
        let hasLegalMove = board.hasAnyLegalMove(for: currentTurn)

        if inCheck && !hasLegalMove {
            // Checkmate — the player who just moved wins.
            gameState = .checkmate
            winner = currentTurn.opposite
        } else if inCheck {
            gameState = .check
        } else {
            gameState = .playing
        }
    }

    // MARK: - Game control

    /// Reset the board to the starting position.
    func newGame() {
        board = Board()
        currentTurn = .cho
        gameState = .playing
        selectedPiece = nil
        validMovesForSelected = []
        winner = nil
    }

    /// The current player resigns — the opponent wins.
    func resign() {
        gameState = .checkmate
        winner = currentTurn.opposite
    }
}

#if DEBUG
// MARK: - Screenshot capture helpers (DEBUG only; launch args never set in production)
extension GameModel {

    /// Show a piece as selected with its legal-move dots (used for the "highlights" shot).
    func forceSelect(at pos: Position) {
        guard let p = board.piece(at: pos) else { return }
        selectedPiece = p
        validMovesForSelected = board.validMoves(for: p)
    }

    /// A short, all-legal development opening that keeps every piece on the board —
    /// horses hop out, chariots shift forward. Tidy "real game" look. Hand-verified
    /// against Janggi's rules (not ported from Xiangqi coordinates, which wouldn't
    /// even be legal under the new move set).
    private func playOpening() {
        let moves: [(Int, Int, Int, Int)] = [
            (1, 0, 2, 2),  // cho   left horse hops out
            (1, 9, 2, 7),  // han   left horse hops out
            (7, 0, 6, 2),  // cho   right horse hops out
            (7, 9, 6, 7),  // han   right horse hops out
            (0, 0, 0, 1),  // cho   left chariot shifts forward
            (0, 9, 0, 8),  // han   left chariot shifts forward
            (8, 0, 8, 1),  // cho   right chariot shifts forward
            (8, 9, 8, 8),  // han   right chariot shifts forward
        ]
        for (fx, fy, tx, ty) in moves {
            board.movePiece(from: Position(x: fx, y: fy), to: Position(x: tx, y: ty))
            currentTurn = currentTurn.opposite
        }
    }

    /// Development-biased legal self-play — evolves the position while keeping most
    /// pieces (only captures clearly-winning material). Deterministic.
    private func selfPlay(plies: Int) {
        for _ in 0..<plies {
            guard board.hasAnyLegalMove(for: currentTurn) else { break }
            var bestFrom: Position?, bestTo: Position?, bestScore = Int.min
            for p in board.pieces(for: currentTurn) {
                for dest in board.validMoves(for: p) {
                    var score = 0
                    if let cap = board.piece(at: dest) { score += cap.type.materialValue / 40 }
                    // advance toward the opponent + favour central files, off the back rank
                    score += (currentTurn == .han ? (9 - dest.y) : dest.y)
                    score -= abs(dest.x - 4)
                    if p.position.y == (currentTurn == .han ? 9 : 0) { score += 3 } // develop back rank
                    // deterministic tiebreak by coordinates
                    let tie = dest.y * 9 + dest.x
                    if score > bestScore || (score == bestScore && tie < ((bestTo.map { $0.y*9+$0.x }) ?? .max)) {
                        bestScore = score; bestFrom = p.position; bestTo = dest
                    }
                }
            }
            if let f = bestFrom, let t = bestTo {
                board.movePiece(from: f, to: t); currentTurn = currentTurn.opposite
            } else { break }
        }
    }

    /// Entry point. name: board | opening | select | midgame
    func captureSetup(_ name: String) {
        newGame()
        switch name {
        case "opening":
            playOpening()
        case "select":
            playOpening()
            forceSelect(at: Position(x: 0, y: 1))   // developed cho chariot — long move line
        case "midgame":
            playOpening(); selfPlay(plies: 10)
        default:
            break   // "board" = fresh starting position
        }
        // Refresh turn indicator / check status for the seeded position.
        let inCheck = board.isInCheck(color: currentTurn)
        gameState = inCheck ? .check : .playing
    }
}
#endif
