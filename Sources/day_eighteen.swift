import Foundation


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
    case UP, RIGHT, DOWN, LEFT
    func getDiff() -> Vec {
        switch self {
        case .UP: return Vec(-1, 0)
        case .RIGHT: return Vec(0, 1)
        case .DOWN: return Vec(1, 0)
        case .LEFT: return Vec(0, -1)
        }
    }

    static func fromCharacter(_ char: Character) -> Direction {
        if char == "<" {
            return .LEFT
        } else if char == ">" {
            return .RIGHT
        } else if char == "^" {
            return .UP
        } else if char == "v" {
            return .DOWN
        } else {
            fatalError("Invalid input to fromCharacter")
        }
    }

    var description: String {
        switch (self) {
            case .UP:
            return "N"
            case .LEFT:
            return "W"
            case .DOWN:
            return "S"
            case .RIGHT:
            return "E"
        }
    }

    func left() -> Direction {
        switch self {
        case .UP: return .LEFT
        case .RIGHT: return .UP
        case .DOWN: return .RIGHT
        case .LEFT: return .DOWN
        }
    }

    func right() -> Direction {
        switch self {
        case .UP: return .RIGHT
        case .RIGHT: return .DOWN
        case .DOWN: return .LEFT
        case .LEFT: return .UP
        }
    }

}

fileprivate struct Trajectory: Comparable {
    let states: [Vec]
    init(_ seq: [Vec]) {
        self.states = seq
    }

    var cost: Int {
        // Number of steps is num states - 1 since we include the initial state
        states.count - 1
    }

    static func >(lhs: Trajectory, rhs: Trajectory) -> Bool{
        lhs.cost > rhs.cost
    }

    static func <(lhs: Trajectory, rhs: Trajectory) -> Bool{
        lhs.cost < rhs.cost
    }

    static func +(lhs: Trajectory, rhs: Vec) -> Trajectory {
        var newSeq = lhs.states
        newSeq.append(rhs)
        return Trajectory(newSeq)
    }

    static func +(lhs: Trajectory, rhs: Direction) -> Trajectory {
        var newSeq = lhs.states
        newSeq.append(rhs.getDiff())
        return Trajectory(newSeq)
    }
}

fileprivate struct Map: CustomStringConvertible {
    var accessible: [Bool]
    let shape: (height: Int, width: Int)
    var start: Vec
    var end: Vec

    init(_ wallLocs: [(Int, Int)], shape dims: (Int, Int)) {
        self.shape = (height: dims.0, width: dims.1)
        self.accessible = Array(repeating: true, count: shape.height * shape.width)

        start = Vec(0, 0)
        end = Vec(shape.height - 1, shape.width - 1)

        for l in wallLocs {
            self[Vec(l.0, l.1)] = false
        }
    }

    var description: String {
        stride(from: 0, to: accessible.count, by: shape.width).map {
            String(accessible[$0..<$0+shape.width].map{$0 ? "." : "#"})
        }.joined(separator: "\n")
    }

    subscript(_ i: Int, _ j: Int) -> Bool{
        get {
            accessible[i * shape.width + j]
        }
        set {
            accessible[i * shape.width + j] = newValue
        }
    }

    subscript(_ pos: Vec) -> Bool {
        get{
            accessible[pos.i * shape.width + pos.j]
        }
        set{
            accessible[pos.i * shape.width + pos.j] = newValue
        }
    }

    func findBestPath() -> Trajectory {
        var queue = PriorityQueue(ascending: true, startingValues: [Trajectory([start])])
        var visited: Set<Vec> = []

        while let trajectory = queue.pop() {
            let curState = trajectory.states.last!
            guard !visited.contains(curState) else { continue }
            visited.insert(curState)

            // Exit conditions
            guard self[curState] else {continue}
            // bc we use priority queue the first solution found is guaranteed to be cost optimal
            if curState == end {
                return trajectory
            }

            queue.push(trajectory + Direction.UP)
            queue.push(trajectory + Direction.DOWN)
            queue.push(trajectory + Direction.LEFT)
            queue.push(trajectory + Direction.RIGHT)
        }

        // If we make it this far we are cooked
        fatalError("Could not find a viable path")
    }
}


fileprivate func parseInput(useTestCase: Bool) -> Map {
    let rawInput: String

    if useTestCase {
        rawInput = """
        5,4
        4,2
        4,5
        3,0
        2,1
        6,3
        2,4
        1,5
        0,6
        3,3
        2,6
        5,1
        1,2
        5,5
        2,5
        6,5
        1,4
        0,4
        6,4
        1,1
        6,1
        1,0
        0,5
        1,6
        2,0
        """
    } else {
        guard let fileCont = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day18") else {
            fatalError("Could not read file")
        }
        rawInput = fileCont
    }

    let locs = rawInput.components(separatedBy: .newlines).map { (line: String) in
        let comps = line.components(separatedBy: ",")
        return (Int(comps[0])!, Int(comps[1])!)
    }

    let sizeLimit = useTestCase ? 12 : 1024
    let walls = Array(locs[..<sizeLimit])
    let shape = useTestCase ? (7, 7) : (71, 71)
    return Map(walls, shape: shape)
}


func dayEighteen_partOne() {
    let map = parseInput(useTestCase: false)
    let bestPath = map.findBestPath()
    print("Day 18 part one: \(bestPath.cost)")
}

