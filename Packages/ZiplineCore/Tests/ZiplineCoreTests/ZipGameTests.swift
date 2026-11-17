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
            let puzzle = ZipPuzzle.generate(size: size, seed: UInt64(size))
            XCTAssertEqual(puzzle.solution.count, size * size)
            XCTAssertEqual(Set(puzzle.solution).count, size * size)
            for pair in zip(puzzle.solution, puzzle.solution.dropFirst()) {
                XCTAssertEqual(abs(pair.0.row - pair.1.row) + abs(pair.0.column - pair.1.column), 1)
            }
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
        _ = game.move(to: puzzle.solution[0]); _ = game.move(to: puzzle.solution[1])
        game.undo(); XCTAssertEqual(game.path.count, 1)
        game.reset(); XCTAssertTrue(game.path.isEmpty)
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