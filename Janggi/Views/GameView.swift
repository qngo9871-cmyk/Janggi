import SwiftUI

/// A regular octagon — Janggi pieces are traditionally carved octagonal wood
/// blocks, not the flat discs used for Xiangqi.
struct Octagon: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<8 {
            let angle = (Double(i) * 45 - 90) * .pi / 180
            let x = cx + r * CGFloat(cos(angle))
            let y = cy + r * CGFloat(sin(angle))
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}

/// Main game view — draws the Janggi board with Canvas and handles interaction.
struct GameView: View {

    @StateObject private var game = GameModel()

    /// If non-nil, this is an AI game and the engine plays the given color.
    var aiEngine: AIEngine?
    /// Whether it's currently the AI's turn and we're waiting for a result.
    @State private var aiThinking = false
    @State private var showEndAlert = false

    // MARK: - Layout constants

    private let boardPadding: CGFloat = 24
    private let pieceScale: CGFloat = 0.88

    var body: some View {
        VStack(spacing: 0) {
            // Turn indicator
            turnIndicator
                .padding(.top, 8)

            // Board area — its own GeometryReader so tap coordinates match drawing coordinates.
            GeometryReader { geo in
                let cellSize = cellSize(in: geo.size)
                let origin = boardOrigin(in: geo.size, cellSize: cellSize)

                ZStack {
                    boardCanvas(cellSize: cellSize, origin: origin)
                    piecesOverlay(cellSize: cellSize, origin: origin)
                        .allowsHitTesting(false) // taps pass through to the ZStack
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    handleTap(at: location, cellSize: cellSize, origin: origin)
                }
            }

            // Buttons
            buttonBar
                .padding(.bottom, 8)
        }
        .background(Color(red: 0.96, green: 0.89, blue: 0.72).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert(endAlertTitle, isPresented: $showEndAlert) {
            Button("New Game") { resetGame() }
            Button("OK", role: .cancel) { }
        }
        .onChange(of: game.gameState) {
            if game.gameState == .checkmate {
                showEndAlert = true
            }
        }
        .onAppear {
            #if DEBUG
            if let name = ProcessInfo.processInfo.environment["JG_CAPTURE"], name != "home" {
                game.captureSetup(name)
            }
            #endif
        }
    }

    // MARK: - Turn indicator

    private var turnIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(game.currentTurn == .han ? Color.red : Color.blue)
                .frame(width: 14, height: 14)
            Text(turnText)
                .font(.headline)
            if aiThinking {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.vertical, 4)
    }

    private var turnText: String {
        switch game.gameState {
        case .checkmate:
            if let w = game.winner {
                return w == .han ? "Han wins!" : "Cho wins!"
            }
            return "Checkmate"
        case .check:
            return (game.currentTurn == .han ? "Han" : "Cho") + " is in CHECK"
        case .playing:
            return (game.currentTurn == .han ? "Han" : "Cho") + "'s turn"
        }
    }

    // MARK: - Button bar

    private var buttonBar: some View {
        HStack(spacing: 20) {
            Button("New Game") { resetGame() }
                .buttonStyle(.bordered)
            Button("Pass") { passTurn() }
                .buttonStyle(.bordered)
                .disabled(aiThinking || game.gameState != .playing)
            Button("Resign") { resignGame() }
                .buttonStyle(.bordered)
                .disabled(game.gameState == .checkmate)
        }
        .padding(.top, 8)
    }

    // MARK: - Board drawing (Canvas)

    private func boardCanvas(cellSize: CGFloat, origin: CGPoint) -> some View {
        Canvas { context, _ in
            let ox = origin.x
            let oy = origin.y
            let lineColor: Color = Color(red: 0.55, green: 0.25, blue: 0.1)

            // Horizontal lines
            for row in 0..<Board.rows {
                let y = oy + CGFloat(row) * cellSize
                var path = Path()
                path.move(to: CGPoint(x: ox, y: y))
                path.addLine(to: CGPoint(x: ox + CGFloat(Board.columns - 1) * cellSize, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 1.2)
            }

            // Vertical lines — continuous top-to-bottom (Janggi has no river gap)
            for col in 0..<Board.columns {
                let x = ox + CGFloat(col) * cellSize
                var path = Path()
                path.move(to: CGPoint(x: x, y: oy))
                path.addLine(to: CGPoint(x: x, y: oy + CGFloat(Board.rows - 1) * cellSize))
                context.stroke(path, with: .color(lineColor), lineWidth: 1.2)
            }

            // Palace diagonals (Cho palace top, Han palace bottom)
            drawLine(context: context, from: (3, 0), to: (5, 2), ox: ox, oy: oy, cell: cellSize, color: lineColor)
            drawLine(context: context, from: (5, 0), to: (3, 2), ox: ox, oy: oy, cell: cellSize, color: lineColor)
            drawLine(context: context, from: (3, 7), to: (5, 9), ox: ox, oy: oy, cell: cellSize, color: lineColor)
            drawLine(context: context, from: (5, 7), to: (3, 9), ox: ox, oy: oy, cell: cellSize, color: lineColor)

            // Highlight valid moves as green dots
            for pos in game.validMovesForSelected {
                let cx = ox + CGFloat(pos.x) * cellSize
                let cy = oy + CGFloat(pos.y) * cellSize
                let dotSize = cellSize * 0.25
                let rect = CGRect(x: cx - dotSize / 2, y: cy - dotSize / 2,
                                  width: dotSize, height: dotSize)
                context.fill(Ellipse().path(in: rect), with: .color(.green.opacity(0.6)))
            }

            // Highlight selected piece with a gold ring
            if let sel = game.selectedPiece {
                let cx = ox + CGFloat(sel.position.x) * cellSize
                let cy = oy + CGFloat(sel.position.y) * cellSize
                let r = cellSize * pieceScale / 2 + 3
                let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                context.stroke(Ellipse().path(in: rect), with: .color(.yellow), lineWidth: 2.5)
            }
        }
    }

    private func drawLine(context: GraphicsContext,
                           from: (Int, Int), to: (Int, Int),
                           ox: CGFloat, oy: CGFloat, cell: CGFloat, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: ox + CGFloat(from.0) * cell, y: oy + CGFloat(from.1) * cell))
        path.addLine(to: CGPoint(x: ox + CGFloat(to.0) * cell, y: oy + CGFloat(to.1) * cell))
        context.stroke(path, with: .color(color), lineWidth: 1.0)
    }

    // MARK: - Pieces overlay

    private func piecesOverlay(cellSize: CGFloat, origin: CGPoint) -> some View {
        ForEach(game.board.pieces, id: \.id) { piece in
            let cx = origin.x + CGFloat(piece.position.x) * cellSize
            let cy = origin.y + CGFloat(piece.position.y) * cellSize
            let diameter = cellSize * pieceScale

            ZStack {
                Octagon()
                    .fill(Color(red: 0.95, green: 0.88, blue: 0.7))
                    .frame(width: diameter, height: diameter)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 2)

                Octagon()
                    .stroke(piece.color == .han ? Color.red : Color.blue, lineWidth: 2)
                    .frame(width: diameter - 4, height: diameter - 4)

                Text(piece.displayCharacter)
                    .font(.system(size: diameter * 0.5, weight: .bold))
                    .foregroundColor(piece.color == .han ? .red : .blue)
            }
            .position(x: cx, y: cy)
        }
    }

    // MARK: - Interaction

    private func handleTap(at location: CGPoint, cellSize: CGFloat, origin: CGPoint) {
        guard !aiThinking, cellSize > 0 else { return }

        let col = Int(round((location.x - origin.x) / cellSize))
        let row = Int(round((location.y - origin.y) / cellSize))
        let pos = Position(x: col, y: row)
        guard pos.isValid else { return }

        game.tap(at: pos)
        triggerAIIfNeeded()
    }

    private func passTurn() {
        game.pass()
        triggerAIIfNeeded()
    }

    private func triggerAIIfNeeded() {
        if let engine = aiEngine,
           game.currentTurn == engine.color,
           game.gameState == .playing || game.gameState == .check {
            triggerAI(engine: engine)
        }
    }

    private func triggerAI(engine: AIEngine) {
        aiThinking = true
        engine.bestMove(board: game.board) { from, to in
            if from == to {
                game.pass()
            } else {
                game.executeMove(from: from, to: to)
            }
            aiThinking = false
        }
    }

    // MARK: - Game control

    private func resetGame() {
        game.newGame()
        aiThinking = false
    }

    private func resignGame() {
        game.resign()
        showEndAlert = true
    }

    // MARK: - Alert

    private var endAlertTitle: String {
        switch game.gameState {
        case .checkmate:
            if let w = game.winner {
                return w == .han ? "Han wins by checkmate!" : "Cho wins by checkmate!"
            }
            return "Checkmate!"
        default:
            return ""
        }
    }

    // MARK: - Layout helpers

    private func cellSize(in size: CGSize) -> CGFloat {
        let w = (size.width  - boardPadding * 2) / CGFloat(Board.columns - 1)
        let h = (size.height - boardPadding * 2) / CGFloat(Board.rows - 1)
        return min(w, h)
    }

    private func boardOrigin(in size: CGSize, cellSize: CGFloat) -> CGPoint {
        let bw = CGFloat(Board.columns - 1) * cellSize
        let bh = CGFloat(Board.rows - 1) * cellSize
        return CGPoint(x: (size.width - bw) / 2, y: (size.height - bh) / 2)
    }
}

#Preview {
    NavigationStack {
        GameView()
    }
}
