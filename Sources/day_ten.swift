import Foundation

fileprivate func parseInput(useTestCase: Bool) -> [[Int]] {
    let rawInput: String
    if useTestCase {
        rawInput = """
        89010123
        78121874
        87430965
        96549874
        45678903
        32019012
        01329801
        10456732
        """
        // rawInput = """
        // 0123
        // 1234
        // 8765
        // 9876
        // """
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day10") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    return rawInput.split(separator: "\n").map { $0.map { $0.wholeNumberValue! } }
}

fileprivate enum Direction: CaseIterable {
    case N, E, S, W
    func getDiff() -> (Int, Int) {
        switch self {
        case .N: return (-1, 0)
        case .E: return (0, 1)
        case .S: return (1, 0)
        case .W: return (0, -1)
        }
    }
    static func fromDiff(_ diff: (Int, Int)) -> Direction {
        switch diff {
        case (-1, 0): return .N
        case (0, 1): return .E
        case (1, 0): return .S
        case (0, -1): return .W
        default: fatalError("Invalid diff")
        }
    }
}

fileprivate struct Vec: Hashable, CustomStringConvertible {
    var i: Int
    var j: Int

    init(_ pos: (Int, Int)) {
        self.i = pos.0
        self.j = pos.1
    }

    var description: String {
        return "(\(i), \(j))"
    }

    static func +(lhs: Vec, rhs: Vec) -> Vec {
        return Vec((lhs.i + rhs.i, lhs.j + rhs.j))
    }
    static func -(lhs: Vec, rhs: Vec) -> Vec {
        return Vec((lhs.i - rhs.i, lhs.j - rhs.j))
    }
    static func +(lhs: Vec, rhs: Direction) -> Vec {
        let diff = rhs.getDiff()
        return Vec((lhs.i + diff.0, lhs.j + diff.1))
    }
}

fileprivate class TopographicMap {
    let map: [[Int]]

    init(map: [[Int]]) {
        self.map = map
    }

    func findTrailheads() -> [Vec] {
        var trailheads: [Vec] = []
        for i in 0..<map.count {
            for j in 0..<map[i].count {
                if map[i][j] == 0 {
                    trailheads.append(Vec((i, j)))
                }
            }
        }
        return trailheads
    }

    func score(_ trailhead: Vec) -> Int {
        let paths = searchForPaths(from: trailhead, withHistory: [])
        // Filter out paths with unique endpoints
        let endpoints = Set(paths.map { $0.last! })
        return endpoints.count
    }

    func rate(_ trailhead: Vec) -> Int {
        let paths = searchForPaths(from: trailhead, withHistory: [])
        return paths.count
    }

    func searchForPaths(from start: Vec, withHistory path: [Vec]) -> [[Vec]] {
        
        guard start.i >= 0, start.i < map.count, start.j >= 0, start.j < map[start.i].count else {
            return []  // this step was invalid (out of bounds)
        }
        guard !path.contains(start) else {
            return []  // this step was invalid (no loops allowed)
        }

        let curVal = map[start.i][start.j]
        var result: [[Vec]] = []
        if path.isEmpty {
            for d in Direction.allCases {
                let next = start + d
                result.append(contentsOf: searchForPaths(from: next, withHistory: [start]))
            }
            return result
        } else {
            let last = path.last!
            let lastVal = map[last.i][last.j]
            guard lastVal == curVal - 1 else {
                return []  // this step was invalid
            }
            if curVal == 9 {  // must be checked after the lastVal check
                return [path + [start]]
            }
            // The current step is valid
            let lastDirection = Direction.fromDiff((last.i - start.i, last.j - start.j))
            for d in Direction.allCases {
                guard d != lastDirection else { continue }
                let next = start + d
                result.append(contentsOf: searchForPaths(from: next, withHistory: path + [start]))
            }
        }
        return result
    }

}

func dayTen_portOne() {
    let data = parseInput(useTestCase: false)

    let map = TopographicMap(map: data)
    let trailheads = map.findTrailheads()

    var scoreSum = 0
    for trailhead in trailheads {
        let score = map.score(trailhead)
        scoreSum += score
    }
    print("Total score: \(scoreSum)")
}


func dayTen_partTwo() {
    let data = parseInput(useTestCase: false)
    let map = TopographicMap(map: data)
    let trailheads = map.findTrailheads()

    var ratingSum = 0
    for trailhead in trailheads {
        let rating = map.rate(trailhead)
        ratingSum += rating
    }
    print("Total rating: \(ratingSum)")
}


// print("Day 10, part 1")
// dayTen_portOne()

// print("Day 10, part 2")
// dayTen_partTwo()