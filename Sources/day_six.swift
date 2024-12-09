import Foundation

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
    func cycle() -> Direction {
        switch self{
            case .N: return .E
            case .E: return .S
            case .S: return .W
            case .W: return .N
        }
    }
}

private struct Position: Hashable, CustomStringConvertible {
    var i: Int
    var j: Int

    init(_ pos: (Int, Int)) {
        self.i = pos.0
        self.j = pos.1
    }

    var description: String {
        return "(\(i), \(j))"
    }
}
enum MapKey: Character {
    case wall = "#"
    case open = "."
    case visited = "X"
}

enum MoveResult: Int {
    case leftarena = 0
    case moved = 1
    case hitwall = 2
}

fileprivate struct Layout {
    var guardPosition: (Int, Int)
    var guardDirection: Direction

    var map: [[Character]]
    var recentlyHitWalls: [((Int, Int), Direction)] = []

    init(map: [[Character]]) {
        self.map = map

        guardPosition = (-1, -1)
        // Apparently the loop isn't good enough for the compiler on its own
        for i in 0..<map.count {
            for j in 0..<map[i].count {
                if map[i][j] == "^" {
                    guardPosition = (i,j)
                    break
                }
            }
        }
        guardDirection = .N
    }

    var guardInArena: Bool {
        return isPositionValid(Position(guardPosition))
    }

    func isPositionValid(_ pos: Position) -> Bool {
        return pos.i >= 0 && pos.i < map.count && pos.j >= 0 && pos.j < map[0].count
    }

    mutating func moveGuard() -> MoveResult {
        if !guardInArena {
            return .leftarena
        }
        self.map[guardPosition.0][guardPosition.1] = MapKey.visited.rawValue

        let (diffX, diffY) = guardDirection.getDiff()
        let targetPosition = (guardPosition.0 + diffX, guardPosition.1 + diffY)
        if targetPosition.0 < 0 || targetPosition.0 >= map.count || targetPosition.1 < 0 || targetPosition.1 >= map[0].count {
            return .leftarena  // Guard leaves arena
        }

        if self.map[targetPosition.0][targetPosition.1] != MapKey.wall.rawValue {
            self.guardPosition = targetPosition
        } else {
            self.recentlyHitWalls.append((targetPosition, guardDirection))
            self.guardDirection = self.guardDirection.cycle()
            return .hitwall
        }
        return .moved
    }

    func printMap() {
        for i in 0..<map.count {
            for j in 0..<map[i].count {
                print(map[i][j], terminator: "")
            }
            print()
        }
    }

    func count(characterType c: Character) -> Int {
        var count = 0
        for i in 0..<map.count {
            for j in 0..<map[i].count {
                if map[i][j] == c {
                    count += 1
                }
            }
        }
        return count
    }

    func getLocations(of c: Character) -> [(Int, Int)] {
        var locations: [(Int, Int)] = []
        for i in 0..<map.count {
            for j in 0..<map[i].count {
                if map[i][j] == c {
                    locations.append((i,j))
                }
            }
        }
        return locations
    }

    func hasCycle() -> Bool {
        var slow = self
        var fast = self

        repeat {
            if slow.moveGuard() == .leftarena {
                return false
            }
            if fast.moveGuard() == .leftarena {
                return false
            }

            if fast.moveGuard() == .leftarena {
                return false
            }
        }
        while (slow.guardPosition != fast.guardPosition || slow.guardDirection != fast.guardDirection)
        return true
    }
}


fileprivate func loadData(useTestCase test: Bool) -> Layout {
    let data: String
    if test {
        data = """
        ....#.....
        .........#
        ..........
        ..#.......
        .......#..
        ..........
        .#..^.....
        ........#.
        #.........
        ......#...
        """
    } else {
        data = try! String(contentsOfFile: "/Users/atanelus/Downloads/input_day6", encoding: .utf8)
    }

    // Convert to character array
    let map = data.split(separator: "\n").map { Array($0) }

    return Layout(map: map)
}

func daySix_partOne() {
    var layout = loadData(useTestCase: false)
    while layout.moveGuard() != .leftarena {
        continue
    }

    print(layout.count(characterType: MapKey.visited.rawValue))
    print(layout.count(characterType: MapKey.wall.rawValue))
}


func daySix_partTwo() {
    var layout = loadData(useTestCase: true)
    let constLayout = layout
    var candidateWalls: Set<Position> = []
    let guardStartPos = Position(layout.guardPosition)
    var confirmedSpots: Set<Position> = []

    let allWalls: Set<Position> = Set(layout.getLocations(of: MapKey.wall.rawValue).map { Position($0) })

    while true {
        let result = layout.moveGuard()
        if result == .leftarena {
            break
        }

        if result == .hitwall && layout.recentlyHitWalls.count >= 3 {
            candidateWalls.removeAll()
            let (wall1, _): ((i: Int, j: Int), Direction) = layout.recentlyHitWalls.last!
            let newDir = layout.guardDirection
            for wall3 in allWalls {
                // Hit direction is the direction of the guard at the time of collision
                // (that is, before turning 90 deg), but newDir is the direction before
                // turning toward the wall we aim to collide with, so it is cycled here
                switch newDir {
                    case .N:  // SW (wall1), SE (wall2), and NE (wall3) walls exist
                        guard wall3.j >= wall1.j + 2 else {continue} // not possible to collide
                        candidateWalls.insert(Position((wall3.i - 1, wall1.j + 1)))
                    case .E: // NW (wall1), SW (wall2), and SE (wall3) walls exist
                        guard wall3.i >= wall1.i + 2 else {continue}
                        candidateWalls.insert(Position((wall1.i + 1, wall3.j + 1)))
                    case .S: // NE (wall1), NW (wall2), and SW (wall3) walls exist
                        guard wall3.j <= wall1.j - 2 else {continue}
                        candidateWalls.insert(Position((wall3.i + 1, wall1.j - 1)))
                    case .W: // SE (wall1), NE (wall2), and NW (wall3) walls exist
                        guard wall3.i <= wall1.i - 2 else {continue}
                        candidateWalls.insert(Position((wall1.i - 1, wall3.j - 1)))
                }
            }

            candidateWalls = candidateWalls.filter { layout.isPositionValid($0) }
            candidateWalls = candidateWalls.filter { layout.map[$0.i][$0.j] != MapKey.wall.rawValue }
            candidateWalls.remove(guardStartPos)

            // Check them for cycles
            for cand in candidateWalls {
                var newMap = constLayout.map
                newMap[cand.i][cand.j] = MapKey.wall.rawValue
                let newLayout = Layout(map: newMap)
                if newLayout.hasCycle() {
                    confirmedSpots.insert(cand)
                }
            }
        }
    }

    print(confirmedSpots)
    print(confirmedSpots.count)
}



print("Day six, part one")
daySix_partOne()

print("Day six, part two")
daySix_partTwo()


// Expected solutions for test case part 2:
// (6,3)
// (7,6)
// (7,7)
// (8,1)
// (8,3)
// (9,7)