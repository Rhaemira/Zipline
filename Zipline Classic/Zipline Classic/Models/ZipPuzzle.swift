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

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

public enum ZipDifficulty: String, CaseIterable, Codable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    public func checkpointCount(for size: Int) -> Int {
        switch self {
        // More checkpoints provide more guidance, so Easy deliberately has the most.
        case .easy: return size + 3
        case .medium: return size + 1
        case .hard: return max(4, size - 1)
        }
    }
}

public struct ZipPuzzle: Equatable, Sendable {
    public let size: Int
    public let checkpoints: [Int: GridPoint]
    public let solution: [GridPoint]
    public let seed: UInt64

    public init(size: Int, checkpoints: [Int: GridPoint], solution: [GridPoint], seed: UInt64) {
        self.size = size
        self.checkpoints = checkpoints
        self.solution = solution
        self.seed = seed
    }

    public var cellCount: Int { size * size }

    public func number(at point: GridPoint) -> Int? {
        checkpoints.first(where: { $0.value == point })?.key
    }

    /// Creates a seeded, reproducible Hamiltonian path. Randomized Warnsdorff ordering
    /// avoids the predictable row-by-row snake used by the first implementation.
    public static func generate(
        size: Int = 6,
        difficulty: ZipDifficulty = .medium,
        seed: UInt64 = UInt64.random(in: 1...UInt64.max)
    ) -> ZipPuzzle {
        let safeSize = min(max(size, 4), 8)
        var rng = SeededGenerator(seed: seed)
        let solution = makeHamiltonianPath(size: safeSize, using: &rng)
        let checkpointCount = min(difficulty.checkpointCount(for: safeSize), solution.count)
        var checkpoints: [Int: GridPoint] = [:]

        for index in 0..<checkpointCount {
            let solutionIndex = index * (solution.count - 1) / (checkpointCount - 1)
            checkpoints[index + 1] = solution[solutionIndex]
        }

        return ZipPuzzle(size: safeSize, checkpoints: checkpoints, solution: solution, seed: seed)
    }

    private static func makeHamiltonianPath(
        size: Int,
        using rng: inout SeededGenerator
    ) -> [GridPoint] {
        let corners = [
            GridPoint(row: 0, column: 0),
            GridPoint(row: 0, column: size - 1),
            GridPoint(row: size - 1, column: 0),
            GridPoint(row: size - 1, column: size - 1)
        ]
        let start = corners[Int.random(in: 0..<corners.count, using: &rng)]
        var visited = Set<GridPoint>()
        var path: [GridPoint] = []
        path.reserveCapacity(size * size)

        func adjacentCells(to point: GridPoint) -> [GridPoint] {
            [
                GridPoint(row: point.row - 1, column: point.column),
                GridPoint(row: point.row + 1, column: point.column),
                GridPoint(row: point.row, column: point.column - 1),
                GridPoint(row: point.row, column: point.column + 1)
            ].filter {
                $0.row >= 0 && $0.row < size && $0.column >= 0 && $0.column < size
            }
        }

        func search(from point: GridPoint) -> Bool {
            visited.insert(point)
            path.append(point)
            if path.count == size * size { return true }

            let candidates = adjacentCells(to: point)
                .filter { !visited.contains($0) }
                .map { candidate -> (point: GridPoint, degree: Int, tie: UInt64) in
                    let degree = adjacentCells(to: candidate).filter { !visited.contains($0) }.count
                    return (candidate, degree, rng.next())
                }
                .sorted {
                    if $0.degree == $1.degree { return $0.tie < $1.tie }
                    return $0.degree < $1.degree
                }

            for candidate in candidates {
                if search(from: candidate.point) { return true }
            }

            visited.remove(point)
            path.removeLast()
            return false
        }

        if search(from: start) { return path }

        // Defensive fallback: a rectangular serpentine path is always Hamiltonian.
        return (0..<size).flatMap { row in
            let columns = row.isMultiple(of: 2) ? Array(0..<size) : Array((0..<size).reversed())
            return columns.map { GridPoint(row: row, column: $0) }
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

public enum MoveResult: Equatable {
    case accepted
    case backtracked
    case rejected
    case completed
}

public struct ZipGame: Sendable {
    public private(set) var puzzle: ZipPuzzle
    public private(set) var path: [GridPoint] = []
    public private(set) var isComplete = false

    public init(puzzle: ZipPuzzle) {
        self.puzzle = puzzle
    }

    public var progress: Double {
        Double(path.count) / Double(puzzle.cellCount)
    }

    public var nextCheckpoint: Int {
        (path.compactMap { puzzle.number(at: $0) }.max() ?? 0) + 1
    }

    /// Returns a safe next cell for the current route, including routes that differ
    /// from the generated reference solution. The search is only run when a hint is requested.
    public var suggestedNextMove: GridPoint? {
        guard !isComplete, path.count < puzzle.cellCount else { return nil }
        if path.isEmpty { return puzzle.checkpoints[1] }
        if path.count < puzzle.solution.count,
           path.elementsEqual(puzzle.solution.prefix(path.count)) {
            return puzzle.solution[path.count]
        }

        var visited = Set(path)
        var searchBudget = 20_000
        guard let current = path.last else { return nil }
        return continuation(
            from: current,
            visited: &visited,
            nextCheckpoint: nextCheckpoint,
            budget: &searchBudget
        )?.first
    }

    private func continuation(
        from current: GridPoint,
        visited: inout Set<GridPoint>,
        nextCheckpoint: Int,
        budget: inout Int
    ) -> [GridPoint]? {
        guard budget > 0 else { return nil }
        budget -= 1
        if visited.count == puzzle.cellCount {
            return puzzle.number(at: current) == puzzle.checkpoints.count ? [] : nil
        }

        let candidates = [
            GridPoint(row: current.row - 1, column: current.column),
            GridPoint(row: current.row + 1, column: current.column),
            GridPoint(row: current.row, column: current.column - 1),
            GridPoint(row: current.row, column: current.column + 1)
        ]
        .filter { candidate in
            candidate.row >= 0 && candidate.row < puzzle.size &&
            candidate.column >= 0 && candidate.column < puzzle.size &&
            !visited.contains(candidate) &&
            (puzzle.number(at: candidate) == nil || puzzle.number(at: candidate) == nextCheckpoint)
        }
        .sorted { lhs, rhs in
            let lhsDegree = availableNeighbors(of: lhs, visited: visited)
            let rhsDegree = availableNeighbors(of: rhs, visited: visited)
            if lhsDegree == rhsDegree {
                if lhs.row == rhs.row { return lhs.column < rhs.column }
                return lhs.row < rhs.row
            }
            return lhsDegree < rhsDegree
        }

        for candidate in candidates {
            visited.insert(candidate)
            let next = puzzle.number(at: candidate) == nextCheckpoint ? nextCheckpoint + 1 : nextCheckpoint
            if let suffix = continuation(
                from: candidate,
                visited: &visited,
                nextCheckpoint: next,
                budget: &budget
            ) {
                return [candidate] + suffix
            }
            visited.remove(candidate)
        }
        return nil
    }

    private func availableNeighbors(of point: GridPoint, visited: Set<GridPoint>) -> Int {
        [
            GridPoint(row: point.row - 1, column: point.column),
            GridPoint(row: point.row + 1, column: point.column),
            GridPoint(row: point.row, column: point.column - 1),
            GridPoint(row: point.row, column: point.column + 1)
        ].filter {
            $0.row >= 0 && $0.row < puzzle.size &&
            $0.column >= 0 && $0.column < puzzle.size &&
            !visited.contains($0)
        }.count
    }

    @discardableResult
    public mutating func move(to point: GridPoint) -> MoveResult {
        guard !isComplete else { return .rejected }

        if path.count > 1 && path[path.count - 2] == point {
            path.removeLast()
            return .backtracked
        }

        guard let last = path.last else {
            guard puzzle.number(at: point) == 1 else { return .rejected }
            path = [point]
            return .accepted
        }

        guard abs(last.row - point.row) + abs(last.column - point.column) == 1,
              !path.contains(point) else { return .rejected }

        if let number = puzzle.number(at: point), number != nextCheckpoint {
            return .rejected
        }

        path.append(point)
        if path.count == puzzle.cellCount {
            guard puzzle.number(at: point) == puzzle.checkpoints.count else {
                path.removeLast()
                return .rejected
            }
            isComplete = true
            return .completed
        }

        return .accepted
    }

    public mutating func undo() {
        guard !path.isEmpty, !isComplete else { return }
        path.removeLast()
    }

    public mutating func reset() {
        path.removeAll()
        isComplete = false
    }

    public mutating func replace(with puzzle: ZipPuzzle) {
        self.puzzle = puzzle
        reset()
    }

    public func isVisited(_ point: GridPoint) -> Bool {
        path.contains(point)
    }
}
