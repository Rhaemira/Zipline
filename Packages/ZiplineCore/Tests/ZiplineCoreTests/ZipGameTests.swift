//
//  ZipGameTests.swift
//  Zipline
//
//  Created by Amirali Yazdani.
//

import XCTest
@testable import ZiplineCore

final class ZipGameTests: XCTestCase {
    func testGeneratedPuzzleHasHamiltonianSolution() {
        for size in 4...8 {
            for seed in 1...12 {
                let puzzle = ZipPuzzle.generate(size: size, seed: UInt64(seed))
                XCTAssertEqual(puzzle.solution.count, size * size)
                XCTAssertEqual(Set(puzzle.solution).count, size * size)
                for pair in zip(puzzle.solution, puzzle.solution.dropFirst()) {
                    XCTAssertEqual(
                        abs(pair.0.row - pair.1.row) + abs(pair.0.column - pair.1.column),
                        1
                    )
                }
                XCTAssertEqual(puzzle.number(at: puzzle.solution.first!), 1)
                XCTAssertEqual(puzzle.number(at: puzzle.solution.last!), puzzle.checkpoints.count)
            }
        }
    }

    func testSeedIsDeterministicAndDifferentSeedsVaryTheRoute() {
        let first = ZipPuzzle.generate(size: 7, difficulty: .hard, seed: 42)
        let repeated = ZipPuzzle.generate(size: 7, difficulty: .hard, seed: 42)
        let different = ZipPuzzle.generate(size: 7, difficulty: .hard, seed: 43)
        XCTAssertEqual(first, repeated)
        XCTAssertNotEqual(first.solution, different.solution)
    }

    func testDifficultyHasDistinctCheckpointDensityAtEverySupportedSize() {
        for size in 4...8 {
            let easy = ZipPuzzle.generate(size: size, difficulty: .easy, seed: 1)
            let medium = ZipPuzzle.generate(size: size, difficulty: .medium, seed: 1)
            let hard = ZipPuzzle.generate(size: size, difficulty: .hard, seed: 1)
            XCTAssertLessThan(easy.checkpoints.count, medium.checkpoints.count)
            XCTAssertLessThan(medium.checkpoints.count, hard.checkpoints.count)
        }
    }

    func testGameAcceptsSolutionAndCompletes() {
        let puzzle = ZipPuzzle.generate(size: 5, difficulty: .easy, seed: 42)
        var game = ZipGame(puzzle: puzzle)
        var result: MoveResult = .accepted
        for point in puzzle.solution { result = game.move(to: point) }
        XCTAssertEqual(result, .completed)
        XCTAssertTrue(game.isComplete)
        XCTAssertEqual(game.path.count, 25)
        XCTAssertEqual(game.progress, 1.0)
    }

    func testRejectsDiagonalAndOutOfOrderStart() {
        let puzzle = ZipPuzzle.generate(size: 5, seed: 7)
        var game = ZipGame(puzzle: puzzle)
        XCTAssertEqual(game.move(to: GridPoint(row: 1, column: 1)), .rejected)
        XCTAssertEqual(game.move(to: puzzle.solution[0]), .accepted)
        XCTAssertEqual(game.move(to: GridPoint(row: 1, column: 1)), .rejected)
    }

    func testUndoAndReset() {
        let puzzle = ZipPuzzle.generate(size: 5, seed: 9)
        var game = ZipGame(puzzle: puzzle)
        _ = game.move(to: puzzle.solution[0])
        _ = game.move(to: puzzle.solution[1])
        game.undo()
        XCTAssertEqual(game.path.count, 1)
        game.reset()
        XCTAssertTrue(game.path.isEmpty)
        XCTAssertEqual(game.progress, 0)
    }

    func testBacktrackingRemovesOnlyTheLastStep() {
        let puzzle = ZipPuzzle.generate(size: 5, seed: 11)
        var game = ZipGame(puzzle: puzzle)
        _ = game.move(to: puzzle.solution[0])
        _ = game.move(to: puzzle.solution[1])
        XCTAssertEqual(game.move(to: puzzle.solution[0]), .backtracked)
        XCTAssertEqual(game.path, [puzzle.solution[0]])
    }

    func testCompletedGameRejectsFurtherMoves() {
        let puzzle = ZipPuzzle.generate(size: 4, difficulty: .easy, seed: 19)
        var game = ZipGame(puzzle: puzzle)
        for point in puzzle.solution { _ = game.move(to: point) }
        XCTAssertEqual(game.move(to: puzzle.solution[0]), .rejected)
    }
}
