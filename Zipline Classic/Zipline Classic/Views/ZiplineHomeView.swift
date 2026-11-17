//
//  ZiplineHomeView.swift
//  Zipline
//
//  Created by Amirali Yazdani.
//
import SwiftUI
import UIKit

struct ZiplineHomeView: View {
    let modernExperience: Bool
    @AppStorage("zipline.appearance") private var appearance = "system"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var size = 6
    @State private var difficulty: ZipDifficulty = .medium
    @State private var game = ZipGame(puzzle: .generate(size: 6, difficulty: .medium))
    @State private var showHowTo = false
    @State private var lastDragPoint: GridPoint?
    @State private var hintedPath: [GridPoint] = []
    @State private var hintMessage = "Plan a route that leaves room to visit every square exactly once."
    @State private var showCompletion = false

    init(modernExperience: Bool = false) { self.modernExperience = modernExperience }

    var body: some View {
        ZStack {
            LinearGradient(colors: [ZiplineStyle.canvas, ZiplineStyle.accent.opacity(0.055), ZiplineStyle.canvas],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Find your flow.").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundColor(ZiplineStyle.ink)
                        Text("Connect the numbers. Fill the board. Make every move count.")
                            .font(.system(size: 15)).foregroundColor(ZiplineStyle.muted)
                    }
                    guideCard
                    boardCard
                    controls
                    HStack {
                        Image(systemName: "sparkles").foregroundColor(ZiplineStyle.accent)
                        Text("A fresh challenge whenever you want one.").font(.system(size: 12, weight: .medium)).foregroundColor(ZiplineStyle.muted)
                    }.frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 30)
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(preferredScheme)
        .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.78), value: game.path)
        .sheet(isPresented: $showHowTo) { instructions }
        .alert("Brilliant!", isPresented: $showCompletion) {
            Button("Play again") { newPuzzle() }
        } message: { Text("You zipped through the whole grid. Ready for another?") }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(ZiplineStyle.accentGradient).frame(width: 46, height: 46)
                Image(systemName: "arrow.turn.down.right").font(.system(size: 23, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("ZIPLINE").font(.system(size: 18, weight: .black, design: .rounded)).tracking(1.6).foregroundColor(ZiplineStyle.ink)
                Text("A little path. A lot of logic.").font(.system(size: 12, weight: .medium)).foregroundColor(ZiplineStyle.muted)
            }
            Spacer()
            Menu {
                Button { appearance = "system" } label: { Label("System", systemImage: "circle.lefthalf.filled") }
                Button { appearance = "light" } label: { Label("Light", systemImage: "sun.max") }
                Button { appearance = "dark" } label: { Label("Dark", systemImage: "moon") }
                Divider()
                Button { showHowTo = true } label: { Label("How to play", systemImage: "questionmark.circle") }
            } label: {
                Image(systemName: appearance == "dark" ? "moon.fill" : (appearance == "light" ? "sun.max.fill" : "circle.lefthalf.filled"))
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(ZiplineStyle.accent)
                    .frame(width: 44, height: 44).background(.thinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.06), lineWidth: 1))
            }
            .accessibilityLabel("Appearance and help")
        }
    }

    private var guideCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(ZiplineStyle.accentGradient).frame(width: 44, height: 44)
                HStack(spacing: 5) {
                    Circle().fill(.white).frame(width: 4, height: 4)
                    Circle().fill(.white).frame(width: 4, height: 4)
                }.offset(y: -4)
                Capsule().stroke(.white, lineWidth: 2).frame(width: 10, height: 5).offset(y: 5)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Meet Zip").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(ZiplineStyle.ink)
                Text("Need a nudge? Hint traces a route to the next checkpoint.")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(ZiplineStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "sparkles").font(.system(size: 17, weight: .semibold)).foregroundColor(ZiplineStyle.accent)
        }
        .padding(13)
        .ziplineCardSurface(modern: modernExperience, radius: 22)
        .accessibilityElement(children: .combine)
    }

    private var boardCard: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("YOUR PUZZLE").font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundColor(ZiplineStyle.muted)
                    Text("\(size) × \(size) grid").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(ZiplineStyle.ink)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(game.progress * 100))%").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(ZiplineStyle.accent)
                    Text("COMPLETE").font(.system(size: 9, weight: .bold)).tracking(1).foregroundColor(ZiplineStyle.muted)
                }
            }
            GeometryReader { proxy in
                let gap: CGFloat = 5
                let side = min((proxy.size.width - CGFloat(size - 1) * gap) / CGFloat(size), 62)
                let boardWidth = side * CGFloat(size) + gap * CGFloat(size - 1)
                VStack(spacing: gap) {
                    ForEach(0..<size, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(0..<size, id: \.self) { column in
                                cell(GridPoint(row: row, column: column), side: side)
                            }
                        }
                    }
                }
                .frame(width: boardWidth, height: boardWidth)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { value in
                    let stride = side + gap
                    let column = Int(value.location.x / stride)
                    let row = Int(value.location.y / stride)
                    guard row >= 0, row < size, column >= 0, column < size,
                          value.location.x.truncatingRemainder(dividingBy: stride) <= side,
                          value.location.y.truncatingRemainder(dividingBy: stride) <= side else { return }
                    let point = GridPoint(row: row, column: column)
                    guard point != lastDragPoint else { return }
                    lastDragPoint = point
                    handle(point)
                }.onEnded { _ in
                    lastDragPoint = nil
                })
            }
            .aspectRatio(1, contentMode: .fit)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(ZiplineStyle.accent.opacity(0.10))
                    Capsule().fill(ZiplineStyle.accentGradient).frame(width: proxy.size.width * game.progress)
                }
            }.frame(height: 6)
            HStack(spacing: 8) {
                Circle().fill(ZiplineStyle.accent).frame(width: 7, height: 7)
                Text("\(game.path.count) of \(size * size) cells connected").font(.system(size: 12, weight: .medium)).foregroundColor(ZiplineStyle.muted)
                Spacer()
                Text("NEXT  \(game.nextCheckpoint)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(ZiplineStyle.accent)
            }
        }
        .padding(18).ziplineCardSurface(modern: modernExperience, radius: 28)
    }

    private func cell(_ point: GridPoint, side: CGFloat) -> some View {
        let number = game.puzzle.number(at: point)
        let visited = game.isVisited(point)
        let isHead = game.path.last == point
        return ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous).fill(visited ? ZiplineStyle.accent : ZiplineStyle.tile)
            if visited { RoundedRectangle(cornerRadius: 11).stroke(.white.opacity(0.28), lineWidth: 1) }
            if let number {
                Text("\(number)").font(.system(size: side * 0.28, weight: .bold, design: .rounded)).foregroundColor(visited ? .white : ZiplineStyle.ink)
            } else if visited { Circle().fill(.white.opacity(0.8)).frame(width: side * 0.12) }
            if isHead { RoundedRectangle(cornerRadius: 11).stroke(.white, lineWidth: 2.5).padding(2) }
            if hintedPath.contains(point) {
                RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Color.cyan.opacity(0.20))
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 3, dash: [5, 3])).padding(1)
            }
            wallEdges(for: point)
        }
        .frame(width: side, height: side).contentShape(Rectangle())
        .accessibilityElement().accessibilityLabel(number.map { "Cell, checkpoint \($0)" } ?? "Cell")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { handle(point) }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("MAKE IT YOURS").font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundColor(ZiplineStyle.muted)
                Spacer()
                Button("New puzzle", action: newPuzzle).font(.system(size: 13, weight: .bold)).foregroundColor(ZiplineStyle.accent)
            }
            HStack(spacing: 8) {
                ForEach([4, 5, 6, 7, 8], id: \.self) { value in
                    Button { size = value; newPuzzle() } label: {
                        Text("\(value)×\(value)").font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(size == value ? .white : ZiplineStyle.muted).frame(maxWidth: .infinity).padding(.vertical, 11)
                            .background(size == value ? ZiplineStyle.accent : ZiplineStyle.surface, in: RoundedRectangle(cornerRadius: 11))
                    }
                }
            }
            HStack(spacing: 8) {
                ForEach(ZipDifficulty.allCases, id: \.self) { value in
                    Button { difficulty = value; newPuzzle() } label: {
                        Text(value.rawValue).font(.system(size: 13, weight: .semibold))
                            .foregroundColor(difficulty == value ? ZiplineStyle.accent : ZiplineStyle.muted).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(difficulty == value ? ZiplineStyle.accent.opacity(0.13) : ZiplineStyle.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            HStack(spacing: 10) {
                actionButton("Undo", icon: "arrow.uturn.backward", style: .secondary) { game.undo() }
                actionButton("Reset", icon: "arrow.counterclockwise", style: .secondary) { game.reset() }
                actionButton("Hint", icon: "lightbulb", style: .primary) {
                    let route = game.revealHintRoute()
                    let checkpoint = game.nextCheckpoint
                    if let index = route.firstIndex(where: { game.puzzle.number(at: $0) == checkpoint }) {
                        hintedPath = Array(route.prefix(through: index))
                        hintMessage = "Follow the highlighted route to checkpoint \(checkpoint). Your path has been rewound to the last correct position."
                    } else {
                        hintedPath = route
                        hintMessage = "Follow the highlighted route to continue the puzzle."
                    }
                }
            }
            if !hintedPath.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb").foregroundColor(.cyan)
                    Text(hintMessage).font(.system(size: 12, weight: .medium)).foregroundColor(ZiplineStyle.muted)
                    Spacer(minLength: 0)
                    Button("Dismiss") { hintedPath = [] }.font(.system(size: 12, weight: .bold))
                }
            }
        }
        .padding(16).ziplineCardSurface(modern: modernExperience, radius: 24)
    }

    @ViewBuilder private func wallEdges(for point: GridPoint) -> some View {
        let top = GridPoint(row: point.row - 1, column: point.column)
        let bottom = GridPoint(row: point.row + 1, column: point.column)
        let left = GridPoint(row: point.row, column: point.column - 1)
        let right = GridPoint(row: point.row, column: point.column + 1)
        ZStack {
            if point.row > 0 && game.puzzle.hasWall(between: point, and: top) {
                VStack { Rectangle().fill(ZiplineStyle.ink.opacity(0.9)).frame(height: 5); Spacer(minLength: 0) }
            }
            if point.row + 1 < size && game.puzzle.hasWall(between: point, and: bottom) {
                VStack { Spacer(minLength: 0); Rectangle().fill(ZiplineStyle.ink.opacity(0.9)).frame(height: 5) }
            }
            if point.column > 0 && game.puzzle.hasWall(between: point, and: left) {
                HStack { Rectangle().fill(ZiplineStyle.ink.opacity(0.9)).frame(width: 5); Spacer(minLength: 0) }
            }
            if point.column + 1 < size && game.puzzle.hasWall(between: point, and: right) {
                HStack { Spacer(minLength: 0); Rectangle().fill(ZiplineStyle.ink.opacity(0.9)).frame(width: 5) }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .allowsHitTesting(false)
    }

    private enum ActionStyle { case primary, secondary }
    private func actionButton(_ title: String, icon: String, style: ActionStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) { Image(systemName: icon); Text(title) }
                .font(.system(size: 13, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 14)
                .foregroundColor(style == .primary ? .white : ZiplineStyle.ink)
                .background(style == .primary ? ZiplineStyle.accentGradient :
                    LinearGradient(colors: [ZiplineStyle.surface, ZiplineStyle.surface], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var instructions: some View {
        NavigationView {
            List {
                instructionRow("01", "Start at 1", "Begin on the cell marked with the number 1.")
                instructionRow("02", "Draw one continuous path", "Move up, down, left, or right. Diagonal moves are not allowed.")
                instructionRow("03", "Connect in order", "Visit each numbered checkpoint in ascending order.")
                instructionRow("04", "Fill every cell", "Visit every square exactly once and finish on the highest number.")
                instructionRow("TIP", "Plan ahead", "Avoid leaving isolated cells or trapping a checkpoint behind your path.")
            }
            .navigationTitle("How to play").navigationBarItems(trailing: Button("Done") { showHowTo = false })
        }
    }

    private func instructionRow(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.system(size: 12, weight: .black, design: .rounded)).foregroundColor(ZiplineStyle.accent)
                .padding(9).background(ZiplineStyle.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); Text(detail).font(.subheadline).foregroundColor(.secondary) }
        }.padding(.vertical, 5)
    }

    private var preferredScheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    private func handle(_ point: GridPoint) {
        switch game.move(to: point) {
        case .accepted, .backtracked:
            hintedPath = []
            UISelectionFeedbackGenerator().selectionChanged()
        case .completed:
            hintedPath = []
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showCompletion = true
        case .rejected:
            if !reduceMotion { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        }
    }

    private func newPuzzle() {
        hintedPath = []
        game.replace(with: .generate(size: size, difficulty: difficulty))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}