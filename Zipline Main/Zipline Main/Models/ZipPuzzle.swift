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

public enum ZipDifficulty: String, CaseIterable, Codable, Sendable {
    case easy = "Easy", medium = "Medium", hard = "Hard"
    public var checkpointCount: Int { switch self { case .easy: 5; case .medium: 7; case .hard: 9 } }
}

public struct ZipPuzzle: Equatable, Sendable {
    public let size: Int
    public let checkpoints: [Int: GridPoint]
    public let solution: [GridPoint]
    public let seed: UInt64

    public init(size: Int, checkpoints: [Int: GridPoint], solution: [GridPoint], seed: UInt64) {
        self.size = size; self.checkpoints = checkpoints; self.solution = solution; self.seed = seed
    }

    public var cellCount: Int { size * size }
    public func number(at point: GridPoint) -> Int? {
        checkpoints.first(where: { $0.value == point })?.key
    }

    public static func generate(size: Int = 6, difficulty: ZipDifficulty = .medium, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) -> ZipPuzzle {
        let safeSize = min(max(size, 4), 8)
        var rows = Array(0..<safeSize)
        var rng = SeededGenerator(seed: seed)
        if Bool.random(using: &rng) { rows.reverse() }
        let startsFromRight = Bool.random(using: &rng)
        var path: [GridPoint] = []
        for (index, row) in rows.enumerated() {
            let leftToRight = index.isMultiple(of: 2) != startsFromRight
            let columns = leftToRight ? Array(0..<safeSize) : Array((0..<safeSize).reversed())
            path.append(contentsOf: columns.map { GridPoint(row: row, column: $0) })
        }
        let count = min(difficulty.checkpointCount, max(3, safeSize + 2))
        var checkpoints: [Int: GridPoint] = [:]
        for number in 0..<count {
            let index = number == 0 ? 0 : (number == count - 1 ? path.count - 1 : (number * (path.count - 1) / (count - 1)))
            checkpoints[number + 1] = path[index]
        }
        return ZipPuzzle(size: safeSize, checkpoints: checkpoints, solution: path, seed: seed)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
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

    @discardableResult public mutating func move(to point: GridPoint) -> MoveResult {
        guard !isComplete else { return .rejected }
        if path.count > 1 && path[path.count - 2] == point {
            path.removeLast(); return .backtracked
        }
        guard let last = path.last else {
            guard puzzle.number(at: point) == 1 else { return .rejected }
            path = [point]; return .accepted
        }
        guard abs(last.row - point.row) + abs(last.column - point.column) == 1,
              !path.contains(point) else { return .rejected }
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