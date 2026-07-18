import Foundation

/// Represents the 9×10 Janggi board and handles all move generation / validation.
///
/// Uses a flat 90-element grid for O(1) lookups and fast value-type copies.
/// Janggi has no river — the board is fully open — but each palace (3×3, marked
/// with an X of diagonal lines) lets the General and Guard move diagonally.
struct Board {

    // MARK: - Constants

    static let columns = 9
    static let rows    = 10

    // MARK: - State

    /// All pieces currently on the board.
    var pieces: [Piece]

    /// Flat grid (row-major, index = y*9 + x) for O(1) lookups. Nil means empty.
    private var grid: [Piece?]

    // MARK: - Init

    init() {
        let initial = Board.initialPieces()
        self.pieces = initial
        self.grid = Board.buildGrid(from: initial)
    }

    init(pieces: [Piece]) {
        self.pieces = pieces
        self.grid = Board.buildGrid(from: pieces)
    }

    private static func buildGrid(from pieces: [Piece]) -> [Piece?] {
        var g = [Piece?](repeating: nil, count: 90)
        for p in pieces {
            g[p.position.y * 9 + p.position.x] = p
        }
        return g
    }

    // MARK: - Grid access

    @inline(__always)
    func piece(at pos: Position) -> Piece? {
        grid[pos.y * 9 + pos.x]
    }

    @inline(__always)
    private func gridAt(_ x: Int, _ y: Int) -> Piece? {
        grid[y * 9 + x]
    }

    func pieces(for color: PieceColor) -> [Piece] {
        pieces.filter { $0.color == color }
    }

    func general(for color: PieceColor) -> Piece? {
        pieces.first { $0.type == .general && $0.color == color }
    }

    // MARK: - Move execution

    @discardableResult
    mutating func movePiece(from origin: Position, to dest: Position) -> Piece? {
        let destIdx = dest.y * 9 + dest.x
        let origIdx = origin.y * 9 + origin.x
        let captured = grid[destIdx]

        if let captured {
            pieces.removeAll { $0.id == captured.id }
        }

        if let idx = pieces.firstIndex(where: { $0.position == origin }) {
            pieces[idx].position = dest
            grid[destIdx] = pieces[idx]
        }
        grid[origIdx] = nil

        return captured
    }

    // MARK: - Valid move generation

    /// Legal moves for a piece (filters out moves that leave own general in check).
    func validMoves(for piece: Piece) -> [Position] {
        rawMoves(for: piece).filter { dest in
            var copy = self
            copy.movePiece(from: piece.position, to: dest)
            return !copy.isInCheck(color: piece.color)
        }
    }

    /// Whether the given color has any legal move (not counting pass). Returns early on first hit.
    func hasAnyLegalMove(for color: PieceColor) -> Bool {
        for p in pieces where p.color == color {
            for dest in rawMoves(for: p) {
                var copy = self
                copy.movePiece(from: p.position, to: dest)
                if !copy.isInCheck(color: color) { return true }
            }
        }
        return false
    }

    // MARK: - Check detection (fast, pattern-based)

    /// Checks if `color`'s General is in check by looking outward from the General's
    /// position for specific attack patterns — much faster than generating all
    /// opponent moves.
    func isInCheck(color: PieceColor) -> Bool {
        guard let king = general(for: color) else { return false }
        let kx = king.position.x
        let ky = king.position.y
        let enemy = color.opposite

        // 1. Chariot / Cannon along orthogonal lines. Janggi has no "flying general"
        //    rule (generals can never leave their palace, so they can never face off
        //    on an open file the way Xiangqi's can) — bikjang is a separate draw
        //    adjudication, not a check/illegal-move condition, and is out of scope.
        let dirs: [(Int, Int)] = [(1,0),(-1,0),(0,1),(0,-1)]
        for (dx, dy) in dirs {
            var x = kx + dx, y = ky + dy
            var screenCount = 0
            var screenIsCannon = false
            while x >= 0 && x <= 8 && y >= 0 && y <= 9 {
                if let occ = gridAt(x, y) {
                    if screenCount == 0 {
                        if occ.color == enemy && occ.type == .chariot { return true }
                        if occ.type == .cannon {
                            // A Cannon can never be jumped by another Cannon, so a
                            // Cannon screen blocks any further Cannon-check along this line.
                            screenIsCannon = true
                        }
                        screenCount = 1
                    } else {
                        // Behind one screen: cannon attacks, unless the screen was itself a cannon.
                        if occ.color == enemy && occ.type == .cannon && !screenIsCannon { return true }
                        break
                    }
                }
                x += dx; y += dy
            }
        }

        // 2. Horse attacks — check all 8 positions a horse could attack from,
        //    verifying the blocking leg is clear.
        let horseMoves: [(fx: Int, fy: Int, bx: Int, by: Int)] = [
            (-1, -2, 0, -1), (1, -2, 0, -1),
            (-1,  2, 0,  1), (1,  2, 0,  1),
            (-2, -1, -1, 0), (-2,  1, -1, 0),
            ( 2, -1,  1, 0), ( 2,  1,  1, 0),
        ]
        for hm in horseMoves {
            let hx = kx + hm.fx, hy = ky + hm.fy
            guard hx >= 0 && hx <= 8 && hy >= 0 && hy <= 9 else { continue }
            let bx = hx + hm.bx, by = hy + hm.by
            guard bx >= 0 && bx <= 8 && by >= 0 && by <= 9 else { continue }
            if gridAt(bx, by) != nil { continue } // leg is blocked, horse can't reach
            if let occ = gridAt(hx, hy), occ.color == enemy && occ.type == .horse {
                return true
            }
        }

        // 3. Elephant attacks — unlike Xiangqi (where Elephants never cross the river
        //    and so can never threaten the enemy General), Janggi Elephants roam the
        //    whole board and CAN give check. Check all 8 "stretched" attack origins,
        //    verifying both hobble legs are clear.
        for em in Board.elephantLegs {
            // Solve for the elephant's own position E such that E + destOffset == king.
            let ex = kx - em.destX, ey = ky - em.destY
            guard ex >= 0 && ex <= 8 && ey >= 0 && ey <= 9 else { continue }
            // Same leg offsets used in elephantMoves, applied relative to E.
            let leg1x = ex + em.leg1X, leg1y = ey + em.leg1Y
            let leg2x = ex + em.leg2X, leg2y = ey + em.leg2Y
            guard leg1x >= 0, leg1x <= 8, leg1y >= 0, leg1y <= 9,
                  leg2x >= 0, leg2x <= 8, leg2y >= 0, leg2y <= 9 else { continue }
            if gridAt(leg1x, leg1y) != nil || gridAt(leg2x, leg2y) != nil { continue }
            if let occ = gridAt(ex, ey), occ.color == enemy && occ.type == .elephant {
                return true
            }
        }

        // 4. Soldier attack — enemy soldier can attack from forward or sideways;
        //    Janggi soldiers can always move sideways (no river-crossing gate).
        let soldierForward = color == .han ? -1 : 1  // direction enemy soldier moves toward our king
        let sy = ky + soldierForward
        if sy >= 0 && sy <= 9 {
            if let occ = gridAt(kx, sy), occ.color == enemy && occ.type == .soldier {
                return true
            }
        }
        for sdx in [-1, 1] {
            let sx = kx + sdx
            guard sx >= 0 && sx <= 8 else { continue }
            if let occ = gridAt(sx, ky), occ.color == enemy && occ.type == .soldier {
                return true
            }
        }

        return false
    }

    // MARK: - Raw move generation

    func rawMoves(for piece: Piece) -> [Position] {
        switch piece.type {
        case .general:  return palaceMoves(piece)
        case .guardian: return palaceMoves(piece)
        case .elephant: return elephantMoves(piece)
        case .horse:    return horseMoves(piece)
        case .chariot:  return chariotMoves(piece)
        case .cannon:   return cannonMoves(piece)
        case .soldier:  return soldierMoves(piece)
        }
    }

    // MARK: General & Guard — 1 step orthogonal always; diagonal only from a
    // palace corner or center, along the marked diagonal lines.
    private func palaceMoves(_ p: Piece) -> [Position] {
        var deltas = [(0,-1),(0,1),(-1,0),(1,0)]
        if isPalaceDiagonalNode(p.position, for: p.color) {
            deltas += [(-1,-1),(-1,1),(1,-1),(1,1)]
        }
        return deltas.compactMap { dx, dy in
            let dest = Position(x: p.position.x+dx, y: p.position.y+dy)
            guard dest.isValid, isInPalace(dest, for: p.color),
                  !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    /// The corner and center points of each palace — the only points a diagonal
    /// palace line actually passes through.
    private func isPalaceDiagonalNode(_ pos: Position, for color: PieceColor) -> Bool {
        let nodes: [(Int, Int)] = color == .han
            ? [(3,7),(5,7),(3,9),(5,9),(4,8)]
            : [(3,0),(5,0),(3,2),(5,2),(4,1)]
        return nodes.contains { $0.0 == pos.x && $0.1 == pos.y }
    }

    // MARK: Elephant — 1 orthogonal step + 2 diagonal steps continuing outward
    // (a "stretched" leap), hobbled if either intervening point is occupied.
    // No side restriction — Janggi's Elephant can reach anywhere on the board.
    private static let elephantLegs: [(leg1X: Int, leg1Y: Int, leg2X: Int, leg2Y: Int, destX: Int, destY: Int)] = [
        (0,-1, -1,-2, -2,-3), (0,-1, 1,-2, 2,-3),
        (0, 1, -1, 2, -2, 3), (0, 1, 1, 2, 2, 3),
        (-1,0, -2,-1, -3,-2), (-1,0, -2, 1, -3, 2),
        (1, 0,  2,-1,  3,-2), (1, 0,  2, 1,  3, 2),
    ]
    private func elephantMoves(_ p: Piece) -> [Position] {
        Board.elephantLegs.compactMap { leg in
            let l1 = (p.position.x + leg.leg1X, p.position.y + leg.leg1Y)
            let l2 = (p.position.x + leg.leg2X, p.position.y + leg.leg2Y)
            guard l1.0 >= 0, l1.0 <= 8, l1.1 >= 0, l1.1 <= 9,
                  l2.0 >= 0, l2.0 <= 8, l2.1 >= 0, l2.1 <= 9 else { return nil }
            if gridAt(l1.0, l1.1) != nil || gridAt(l2.0, l2.1) != nil { return nil }
            let dest = Position(x: p.position.x + leg.destX, y: p.position.y + leg.destY)
            guard dest.isValid, !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    // MARK: Horse — L-shape with hobble leg (identical to Xiangqi)
    private func horseMoves(_ p: Piece) -> [Position] {
        let moveSets: [(ox:Int,oy:Int,fx:Int,fy:Int)] = [
            (0,-1,-1,-2),(0,-1,1,-2),(0,1,-1,2),(0,1,1,2),
            (-1,0,-2,-1),(-1,0,-2,1),(1,0,2,-1),(1,0,2,1),
        ]
        return moveSets.compactMap { ms in
            let bx = p.position.x+ms.ox, by = p.position.y+ms.oy
            guard bx >= 0 && bx <= 8 && by >= 0 && by <= 9 else { return nil }
            if gridAt(bx, by) != nil { return nil }
            let dest = Position(x: p.position.x+ms.fx, y: p.position.y+ms.fy)
            guard dest.isValid, !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    // MARK: Chariot — slides orthogonally, unchanged from Xiangqi
    private func chariotMoves(_ p: Piece) -> [Position] {
        var moves = [Position]()
        moves.reserveCapacity(17)
        for (dx,dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
            var x = p.position.x+dx, y = p.position.y+dy
            while x >= 0 && x <= 8 && y >= 0 && y <= 9 {
                if let occ = gridAt(x, y) {
                    if occ.color != p.color { moves.append(Position(x:x,y:y)) }
                    break
                }
                moves.append(Position(x:x,y:y))
                x += dx; y += dy
            }
        }
        return moves
    }

    // MARK: Cannon — Janggi's cannon needs a screen to move AT ALL, not just to
    // capture (Xiangqi's cannon slides freely and only needs a screen to capture).
    // It can never use another Cannon as a screen, and can never capture a Cannon.
    private func cannonMoves(_ p: Piece) -> [Position] {
        var moves = [Position]()
        moves.reserveCapacity(17)
        for (dx,dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
            var x = p.position.x+dx, y = p.position.y+dy
            var jumped = false
            while x >= 0 && x <= 8 && y >= 0 && y <= 9 {
                if let occ = gridAt(x, y) {
                    if !jumped {
                        if occ.type == .cannon { break } // can't screen off another cannon
                        jumped = true
                    } else {
                        if occ.color != p.color && occ.type != .cannon {
                            moves.append(Position(x:x,y:y))
                        }
                        break
                    }
                } else if jumped {
                    moves.append(Position(x:x,y:y))
                }
                // No screen found yet: empty squares before it are NOT valid destinations.
                x += dx; y += dy
            }
        }
        return moves
    }

    // MARK: Soldier — forward or sideways, never backward, from the very start
    // (Janggi has no river-crossing mechanic).
    private func soldierMoves(_ p: Piece) -> [Position] {
        let deltas = [(0, p.color.forwardDelta), (-1, 0), (1, 0)]
        return deltas.compactMap { dx, dy in
            let dest = Position(x: p.position.x+dx, y: p.position.y+dy)
            guard dest.isValid, !isFriendly(dest, p.color) else { return nil }
            return dest
        }
    }

    // MARK: - Helpers

    @inline(__always)
    private func isInPalace(_ pos: Position, for color: PieceColor) -> Bool {
        color == .han ? pos.isInHanPalace : pos.isInChoPalace
    }

    @inline(__always)
    private func isFriendly(_ pos: Position, _ color: PieceColor) -> Bool {
        if let p = grid[pos.y * 9 + pos.x], p.color == color { return true }
        return false
    }

    // MARK: - Initial setup

    static func initialPieces() -> [Piece] {
        var r = [Piece]()
        r.reserveCapacity(32)

        func sym(_ t: PieceType, _ c: PieceColor, _ x: Int, _ y: Int) {
            r.append(Piece(type:t,color:c,position:Position(x:x,y:y)))
            if x != 8-x { r.append(Piece(type:t,color:c,position:Position(x:8-x,y:y))) }
        }

        // Cho (top, moves first)
        sym(.chariot,.cho,0,0); sym(.horse,.cho,1,0); sym(.elephant,.cho,2,0)
        sym(.guardian,.cho,3,0)
        r.append(Piece(type:.general,color:.cho,position:Position(x:4,y:1)))
        sym(.cannon,.cho,1,2)
        for x in stride(from:0,through:8,by:2) { r.append(Piece(type:.soldier,color:.cho,position:Position(x:x,y:3))) }

        // Han (bottom)
        sym(.chariot,.han,0,9); sym(.horse,.han,1,9); sym(.elephant,.han,2,9)
        sym(.guardian,.han,3,9)
        r.append(Piece(type:.general,color:.han,position:Position(x:4,y:8)))
        sym(.cannon,.han,1,7)
        for x in stride(from:0,through:8,by:2) { r.append(Piece(type:.soldier,color:.han,position:Position(x:x,y:6))) }

        return r
    }
}
