//
//  ZipPuzzle.swift
//  Zipline
//
//  Created by Amirali Yazdani.
//
import Foundation

public struct GridPoint: Hashable, Codable, Sendable {
    public let row: Int
    public let column: Int
    public init(row: Int, column: Int) { self.row = row; self.column = column }
}

/// A thick barrier between two orthogonally adjacent cells.
public struct ZipWall: Hashable, Codable, Sendable {
    public let first: GridPoint
    public let second: GridPoint
    public init(_ a: GridPoint, _ b: GridPoint) {
        if a.row < b.row || (a.row == b.row && a.column <= b.column) { first = a; second = b }
        else { first = b; second = a }
    }
}

public enum ZipDifficulty: String, CaseIterable, Codable, Sendable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    public func checkpointCount(for size: Int) -> Int {
        switch self { case .easy: return size + 3; case .medium: return size + 1; case .hard: return max(4, size - 1) }
    }
    public func wallCount(for size: Int) -> Int {
        switch self { case .easy: return max(2, size / 2); case .medium: return size; case .hard: return size + size / 2 }
    }
}

public struct ZipPuzzle: Equatable, Sendable {
    public let size: Int
    public let checkpoints: [Int: GridPoint]
    public let solution: [GridPoint]
    public let walls: Set<ZipWall>
    public let seed: UInt64

    public init(size: Int, checkpoints: [Int: GridPoint], solution: [GridPoint], walls: Set<ZipWall> = [], seed: UInt64) {
        self.size = size; self.checkpoints = checkpoints; self.solution = solution; self.walls = walls; self.seed = seed
    }
    public var cellCount: Int { size * size }
    public func number(at point: GridPoint) -> Int? { checkpoints.first(where: { $0.value == point })?.key }
    public func hasWall(between a: GridPoint, and b: GridPoint) -> Bool { walls.contains(ZipWall(a, b)) }

    public static func generate(size: Int = 6, difficulty: ZipDifficulty = .medium, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) -> ZipPuzzle {
        let n = min(max(size, 4), 8)
        var rng = SeededGenerator(seed: seed)
        let solution = makeHamiltonianPath(size: n, using: &rng)
        let count = min(difficulty.checkpointCount(for: n), solution.count)
        var checkpoints: [Int: GridPoint] = [:]
        for index in 0..<count { checkpoints[index + 1] = solution[index * (solution.count - 1) / (count - 1)] }
        let solutionEdges = Set(zip(solution, solution.dropFirst()).map { ZipWall($0.0, $0.1) })
        var candidates: [ZipWall] = []
        for row in 0..<n {
            for column in 0..<n {
                let point = GridPoint(row: row, column: column)
                if column + 1 < n {
                    let edge = ZipWall(point, GridPoint(row: row, column: column + 1))
                    if !solutionEdges.contains(edge) { candidates.append(edge) }
                }
                if row + 1 < n {
                    let edge = ZipWall(point, GridPoint(row: row + 1, column: column))
                    if !solutionEdges.contains(edge) { candidates.append(edge) }
                }
            }
        }
        for index in candidates.indices.reversed() {
            let other = Int.random(in: 0...index, using: &rng)
            candidates.swapAt(index, other)
        }
        let walls = Set(candidates.prefix(min(difficulty.wallCount(for: n), candidates.count)))
        return ZipPuzzle(size: n, checkpoints: checkpoints, solution: solution, walls: walls, seed: seed)
    }

    private static func makeHamiltonianPath(size: Int, using rng: inout SeededGenerator) -> [GridPoint] {
        let corners = [GridPoint(row: 0, column: 0), GridPoint(row: 0, column: size - 1),
                       GridPoint(row: size - 1, column: 0), GridPoint(row: size - 1, column: size - 1)]
        let start = corners[Int.random(in: 0..<corners.count, using: &rng)]
        var visited = Set<GridPoint>()
        var path: [GridPoint] = []
        path.reserveCapacity(size * size)
        func neighbors(_ point: GridPoint) -> [GridPoint] {
            [GridPoint(row: point.row - 1, column: point.column), GridPoint(row: point.row + 1, column: point.column),
             GridPoint(row: point.row, column: point.column - 1), GridPoint(row: point.row, column: point.column + 1)]
                .filter { $0.row >= 0 && $0.row < size && $0.column >= 0 && $0.column < size }
        }
        func search(_ point: GridPoint) -> Bool {
            visited.insert(point); path.append(point)
            if path.count == size * size { return true }
            var options: [(point: GridPoint, degree: Int, tie: UInt64)] = []
            for candidate in neighbors(point) where !visited.contains(candidate) {
                options.append((candidate, neighbors(candidate).filter { !visited.contains($0) }.count, rng.next()))
            }
            options.sort { $0.degree == $1.degree ? $0.tie < $1.tie : $0.degree < $1.degree }
            for option in options where search(option.point) { return true }
            visited.remove(point); path.removeLast()
            return false
        }
        if search(start) { return path }
        return (0..<size).flatMap { row in
            (row.isMultiple(of: 2) ? Array(0..<size) : Array((0..<size).reversed())).map { GridPoint(row: row, column: $0) }
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

public enum MoveResult: Equatable { case accepted, backtracked, rejected, completed }

public struct ZipGame: Sendable {
    public private(set) var puzzle: ZipPuzzle
    public private(set) var path: [GridPoint] = []
    public private(set) var isComplete = false
    public init(puzzle: ZipPuzzle) { self.puzzle = puzzle }
    public var progress: Double { Double(path.count) / Double(puzzle.cellCount) }
    public var nextCheckpoint: Int { (path.compactMap { puzzle.number(at: $0) }.max() ?? 0) + 1 }

    /// Rewinds a wrong branch to the longest correct prefix, then returns the full
    /// known-good route through the next checkpoint (and beyond).
    @discardableResult public mutating func revealHintRoute() -> [GridPoint] {
        guard !isComplete else { return [] }
        var common = 0
        while common < path.count && common < puzzle.solution.count && path[common] == puzzle.solution[common] { common += 1 }
        if common < path.count { path = Array(path.prefix(common)) }
        return Array(puzzle.solution.dropFirst(path.count))
    }

    @discardableResult public mutating func move(to point: GridPoint) -> MoveResult {
        guard !isComplete else { return .rejected }
        if path.count > 1 && path[path.count - 2] == point { path.removeLast(); return .backtracked }
        guard let last = path.last else {
            guard puzzle.number(at: point) == 1 else { return .rejected }
            path = [point]; return .accepted
        }
        guard abs(last.row - point.row) + abs(last.column - point.column) == 1,
              !path.contains(point), !puzzle.hasWall(between: last, and: point) else { return .rejected }
        if let number = puzzle.number(at: point), number != nextCheckpoint { return .rejected }
        path.append(point)
        if path.count == puzzle.cellCount {
            guard puzzle.number(at: point) == puzzle.checkpoints.count else { path.removeLast(); return .rejected }
            isComplete = true; return .completed
        }
        return .accepted
    }
    public mutating func undo() { guard !path.isEmpty, !isComplete else { return }; path.removeLast() }
    public mutating func reset() { path.removeAll(); isComplete = false }
    public mutating func replace(with puzzle: ZipPuzzle) { self.puzzle = puzzle; reset() }
    public func isVisited(_ point: GridPoint) -> Bool { path.contains(point) }
}
