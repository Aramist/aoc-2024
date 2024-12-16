import Foundation


fileprivate enum MapItem: Character {
    case Robot = "@"
    case Wall = "#"
    case Empty = "."
    case Box = "O"
    case BoxL = "["
    case BoxR = "]"
}

fileprivate struct Vec: Hashable, Equatable, Comparable {
    var i: Int, j: Int

    init(_ i: Int, _ j: Int) {
        self.i = i
        self.j = j
    }

    func dot(_ other: Vec) -> Int{
        return i * other.i + j * other.j
    }

    static func +(lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.i + rhs.i, lhs.j + rhs.j)
    }

    static func +(lhs: Vec, rhs: Direction) -> Vec {
        return lhs + rhs.getDiff()
    }

    static func -(lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.i - rhs.i, lhs.j - rhs.j)
    }
    static func *(lhs: Vec, rhs: Int) -> Vec {
        return Vec(lhs.i * rhs, lhs.j * rhs)
    }

    static func +=(self: inout Vec, other: Vec) {
        self.i += other.i
        self.j += other.j
    }

    static func -=(self: inout Vec, other: Vec) {
        self.i -= other.i
        self.j -= other.j
    }

    static func *=(self: inout Vec, other: Int) {
        self.i *= other
        self.j *= other
    }

    static func >(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.i > rhs.i && lhs.j > rhs.j
    }

    static func <(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.i < rhs.i && lhs.j < rhs.j
    }

    static func >=(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.i >= rhs.i && lhs.j >= rhs.j
    }
    static func <=(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.i <= rhs.i && lhs.j <= rhs.j
    }

    static func ==(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.i == rhs.i && lhs.j == rhs.j
    }
}

fileprivate enum Direction: CaseIterable, CustomStringConvertible {
    case N, E, S, W
    func getDiff() -> Vec {
        switch self {
        case .N: return Vec(-1, 0)
        case .E: return Vec(0, 1)
        case .S: return Vec(1, 0)
        case .W: return Vec(0, -1)
        }
    }

    static func fromCharacter(_ char: Character) -> Direction {
        if char == "<" {
            return .W
        } else if char == ">" {
            return .E
        } else if char == "^" {
            return .N
        } else if char == "v" {
            return .S
        } else {
            fatalError("Invalid input to fromCharacter")
        }
    }

    var description: String {
        switch (self) {
            case .N:
            return "N"
            case .W:
            return "W"
            case .S:
            return "S"
            case .E:
            return "E"
        }
    }
}

fileprivate struct Map: CustomStringConvertible {
    var chars: [MapItem]
    let shape: (height: Int, width: Int)

    init(_ characters: String) {

        let mapSplit = characters.split(separator: "\n")
        let width = mapSplit[0].count
        let height = mapSplit.count
        self.shape = (height: height, width: width)
        self.chars = Array(characters).filter{$0 != "\n"}.map{MapItem(rawValue: $0)!}
    }

    var description: String {
        stride(from: 0, to: chars.count, by: shape.width).map {
            String(chars[$0..<$0+shape.width].map{$0.rawValue})
        }.joined(separator: "\n")
    }

    subscript(_ i: Int, _ j: Int) -> MapItem{
        get {
            chars[i * shape.width + j]
        }
        set {
            chars[i * shape.width + j] = newValue
        }
    }

    subscript(_ pos: Vec) -> MapItem {
        get{
            chars[pos.i * shape.width + pos.j]
        }
        set{
            chars[pos.i * shape.width + pos.j] = newValue
        }
    }

    var robotPosition: Vec {
        guard let p = chars.firstIndex(of: .Robot) else {
            fatalError("no robot?")
        }
        let j = p % self.shape.width
        let i = p / self.shape.width
        return Vec(i, j)
    }

    mutating func attemptMove(inDirection direction: Direction) {
        let curPos = robotPosition
        let ahead = curPos + direction

        if self[ahead] == .Wall {
            return
        } else if self[ahead] == .Empty {
            self[ahead] = .Robot
            self[curPos] = .Empty
            return
        }

        // Box ahead
        var boxLocations = [ahead]
        while true {
            let further = boxLocations.last! + direction
            // assuming the arena is bounded by walls, we don't need index bounds checks
            guard self[further] != .Wall else { return }  // Cant push boxes past a wall
            guard self[further] != .Empty else { break }
            boxLocations.append(further)
        }

        self[boxLocations.last! + direction] = .Box
        self[boxLocations.first!] = .Robot
        self[curPos] = .Empty
    }

    func findAll(item char: MapItem) -> [Vec] {
        var results = [Vec]()
        for idx in 0..<chars.count {
            let j = idx % self.shape.width
            let i = idx / self.shape.width
            if self[i,j] == char {
                results.append(Vec(i,j))
            }
        }
        return results
    }
}

fileprivate struct ExpandedMap: CustomStringConvertible {
    var chars: [MapItem]
    let shape: (height: Int, width: Int)

    static func partTwoConvert(_ char: Character) -> String {
        if char == "#" { return "##"}
        else if char == "@" { return "@."}
        else if char == "." { return ".."}
        else if char == "O" { return "[]"}
        else { fatalError("Invalid character in map")}
    }

    init(_ characters: String) {

        let mapSplit = characters.split(separator: "\n")
        let width = mapSplit[0].count * 2
        let height = mapSplit.count
        self.shape = (height: height, width: width)
        chars = Array(characters).filter{$0 != "\n"}.map{
            ExpandedMap.partTwoConvert($0)
        }.joined(separator: "").map{MapItem(rawValue: $0)!  }
    }

    var description: String {
        stride(from: 0, to: chars.count, by: shape.width).map {
            String(chars[$0..<$0+shape.width].map{$0.rawValue})
        }.joined(separator: "\n")
    }

    subscript(_ i: Int, _ j: Int) -> MapItem{
        get {
            chars[i * shape.width + j]
        }
        set {
            chars[i * shape.width + j] = newValue
        }
    }

    subscript(_ pos: Vec) -> MapItem {
        get{
            chars[pos.i * shape.width + pos.j]
        }
        set{
            chars[pos.i * shape.width + pos.j] = newValue
        }
    }

    var robotPosition: Vec {
        guard let p = chars.firstIndex(of: .Robot) else {
            fatalError("no robot?")
        }
        let j = p % self.shape.width
        let i = p / self.shape.width
        return Vec(i, j)
    }

    mutating func attemptMove(inDirection direction: Direction) {
        let curPos = robotPosition
        let ahead = curPos + direction

        if self[ahead] == .Wall {
            return
        } else if self[ahead] == .Empty {
            self[ahead] = .Robot
            self[curPos] = .Empty
            return
        }

        // Box ahead
        var movingBoxes = Set<Vec>() // Only store lefts
        var boxQueue = [ahead]
        while !boxQueue.isEmpty {
            var curBox = boxQueue.removeFirst()
            if self[curBox] == .BoxR {
                curBox = curBox + Direction.W
            }
            guard !movingBoxes.contains(curBox) else {continue}
            movingBoxes.insert(curBox)

            if direction == .E {
                let further = curBox + direction + direction
                if self[further] == .Empty { continue }
                else if self[further] == .Wall {
                    movingBoxes.removeAll()
                    break
                } else {
                    boxQueue.append(further)
                }
            } else if direction == .W {
                let further = curBox + direction
                if self[further] == .Empty { continue }
                else if self[further] == .Wall {
                    movingBoxes.removeAll()
                    break
                } else {
                    boxQueue.append(further)
                }
            } else { // North or South
                let furtherL = curBox + direction
                let furtherR = furtherL + .E
                if self[furtherL] == .Empty && self[furtherR] == .Empty {
                    continue
                } else if self[furtherL] == .Wall || self[furtherR] == .Wall {
                    movingBoxes.removeAll()
                    break
                }
                if self[furtherL] == .BoxL || self[furtherL] == .BoxR {
                    boxQueue.append(furtherL)
                }
                if self[furtherR] == .BoxL || self[furtherR] == .BoxR {
                    boxQueue.append(furtherR)
                }
            }
        }
        // Push boxes
        
        let shiftedBoxes = movingBoxes.map{$0 + direction}
        movingBoxes.forEach {
            self[$0] = .Empty
            self[$0 + Direction.E] = .Empty
        }
        shiftedBoxes.forEach {
            self[$0] = .BoxL
            self[$0 + Direction.E] = .BoxR
        }
        if movingBoxes.isEmpty { return }
        self[curPos] = .Empty
        self[curPos + direction] = .Robot
    }

    func findAll(item char: MapItem) -> [Vec] {
        var results = [Vec]()
        for idx in 0..<chars.count {
            let j = idx % self.shape.width
            let i = idx / self.shape.width
            if self[i,j] == char {
                results.append(Vec(i,j))
            }
        }
        return results
    }
}

fileprivate func parseInput(useTestCase: Bool) -> (ExpandedMap, [Direction]) {
    let rawInput: String
    if useTestCase {
        // rawInput = """
        // ########
        // #..O.O.#
        // ##@.O..#
        // #...O..#
        // #.#.O..#
        // #...O..#
        // #......#
        // ########

        // <^^>>>vv<v>>v<<
        // """
        rawInput = """
        ##########
        #..O..O.O#
        #......O.#
        #.OO..O.O#
        #..O@..O.#
        #O#..O...#
        #O..O..O.#
        #.OO.O.OO#
        #....O...#
        ##########

        <vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        ><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        <<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        ^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        ^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        >^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        <><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        ^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
        """
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day15") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    guard #available(macOS 13, *) else {fatalError("bruh")}

    let mapRaw = String(rawInput.split(separator: "\n\n")[0])
    let movesRaw = rawInput.split(separator: "\n\n")[1...]
    let map = ExpandedMap(mapRaw)

    let moves = movesRaw.joined().filter{$0 != "\n"}.map{Direction.fromCharacter($0)}
    return (map, moves)
}



func dayFifteen_partOne() {

    var (map, moves) = parseInput(useTestCase: false)

    print(map)
    print()
    print(moves)

    print()
    for dir in moves {
        map.attemptMove(inDirection: dir)
    }
    print(map)

    let sum = map.findAll(item: .Box).reduce(0) { (acc, bloc) in 
        return acc + bloc.dot(Vec(100, 1))
    }
    print(sum)
}


func dayFifteen_partTwo() {
    var (map, moves) = parseInput(useTestCase: false)

    moves.forEach { 
        map.attemptMove(inDirection: $0)
    }

    let sum = map.findAll(item: .BoxL).reduce(0) { (acc, bloc) in 
        return acc + bloc.dot(Vec(100, 1))
    }
    print(sum)

}