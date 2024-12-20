import Foundation


fileprivate enum MapItem: Character {
    case Wall = "#"
    case Empty = "."
    case Goal = "E"
    case Start = "S"
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

    func left() -> Direction {
        switch self {
        case .N: return .W
        case .E: return .N
        case .S: return .E
        case .W: return .S
        }
    }

    func right() -> Direction {
        switch self {
        case .N: return .E
        case .E: return .S
        case .S: return .W
        case .W: return .N
        }
    }

}

fileprivate enum Movement: CustomStringConvertible {
    case Forward
    case TurnL
    case TurnR

    var cost: Int {
        switch (self) {
            case .Forward:
            return 1
            case .TurnL:
            return 1000
            case .TurnR:
            return 1000
        }
    }

    var description: String {
        switch(self) {
            case .Forward:
            return "F"
            case .TurnL:
            return "L"
            case .TurnR:
            return "R"
        }
    }
}

fileprivate struct State: Hashable {
    let pos: Vec
    let dir: Direction
}

fileprivate struct MovementSequence: Comparable {
    let moves: [Movement]
    let state: State
    init(_ seq: [Movement], _ state: State) {
        self.moves = seq
        self.state = state
    }

    var cost: Int {
        moves.reduce(0) {(acc, mov) in 
            acc + mov.cost
        }
    }

    static func >(lhs: MovementSequence, rhs: MovementSequence) -> Bool{
        lhs.cost > rhs.cost
    }

    static func <(lhs: MovementSequence, rhs: MovementSequence) -> Bool{
        lhs.cost < rhs.cost
    }

    static func +(lhs: MovementSequence, rhs: Movement) -> MovementSequence {
        var newSeq = lhs.moves
        newSeq.append(rhs)
        let newState: State
        switch rhs {
            case .Forward:
            newState = State(pos: lhs.state.pos + lhs.state.dir, dir: lhs.state.dir)
            case .TurnR:
            newState = State(pos: lhs.state.pos, dir: lhs.state.dir.right())
            case .TurnL:
            newState = State(pos: lhs.state.pos, dir: lhs.state.dir.left())
        }
        return MovementSequence(newSeq, newState)
    }
}

fileprivate struct Map: CustomStringConvertible {
    var chars: [MapItem]
    let shape: (height: Int, width: Int)
    var reindeerLoc: Vec
    var reindeerDir: Direction

    init(_ characters: String) {

        let mapSplit = characters.split(separator: "\n")
        let width = mapSplit[0].count
        let height = mapSplit.count
        self.shape = (height: height, width: width)
        self.chars = Array(characters).filter{$0 != "\n"}.map{MapItem(rawValue: $0)!}

        guard let p = chars.firstIndex(of: .Start) else {
            fatalError("no reindeer?")
        }
        let j = p % self.shape.width
        let i = p / self.shape.width
        reindeerLoc = Vec(i, j)
        reindeerDir = .E
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

    func simulate(sequence seq: MovementSequence) -> [State] {
        var pos = self.reindeerLoc
        var dir = self.reindeerDir

        var hitStates: [State] = []

        for mov in seq.moves {
            hitStates.append(State(pos: pos, dir: dir))
            switch mov {
                case .Forward:
                    pos = pos + dir
                case .TurnL:
                    dir = dir.left()
                case .TurnR:
                    dir = dir.right()
            }

            guard self[pos] != .Wall else {return hitStates}
        }
        hitStates.append(State(pos: pos, dir: dir))
        return hitStates
    }

    func findBestPath() -> MovementSequence {
        // var queue: [MovementSequence] = [MovementSequence([])]
        var queue = PriorityQueue(ascending: true, startingValues: [MovementSequence([], State(pos: reindeerLoc, dir: reindeerDir))])
        var visited: Set<State> = []

        while let trajectory = queue.pop() {
            let curState = trajectory.state
            guard !visited.contains(curState) else { continue }
            visited.insert(curState)

            // Exit conditions
            if self[curState.pos] == .Wall {
                continue
            }
            // bc we use priority queue the first solution found is guaranteed to be cost optimal
            if self[curState.pos] == .Goal {
                return trajectory
            }

            queue.push(trajectory + .Forward)
            queue.push(trajectory + .TurnL)
            queue.push(trajectory + .TurnR)
        }

        // If we make it this far we are cooked
        fatalError("Could not find a viable path")
    }

    func findAllBestPaths() -> [MovementSequence] {
        var queue = PriorityQueue(ascending: true, startingValues: [MovementSequence([], State(pos: reindeerLoc, dir: reindeerDir))])
        var visited: Set<State> = []

        var bestPaths: [MovementSequence] = []

        while let trajectory = queue.pop() {
            let curState = trajectory.state
            guard !visited.contains(curState) else { continue }
            visited.insert(curState)

            // Exit conditions
            if self[curState.pos] == .Wall {
                continue
            }
            // bc we use priority queue the first solution found is guaranteed to be cost optimal
            if self[curState.pos] == .Goal {
                guard let prevBest = bestPaths.last else {
                    bestPaths.append(trajectory)
                    // Remove all states in this trajectory from visited
                    for state in simulate(sequence: trajectory) {
                        visited.remove(state)
                    }
                    continue
                }
                print(trajectory)
                print(prevBest.cost, trajectory.cost)

                if trajectory.cost == prevBest.cost {
                    bestPaths.append(trajectory)
                    continue
                }
                return bestPaths
            }

            queue.push(trajectory + .Forward)
            queue.push(trajectory + .TurnL)
            queue.push(trajectory + .TurnR)
        }

        fatalError("Could not find a viable path")
    }
}


fileprivate func parseInput(useTestCase: Bool) -> Map {
    let rawInput: String
    if useTestCase {
        rawInput = """
        ###############
        #.......#....E#
        #.#.###.#.###.#
        #.....#.#...#.#
        #.###.#####.#.#
        #.#.#.......#.#
        #.#.#####.###.#
        #...........#.#
        ###.#.#####.#.#
        #...#.....#.#.#
        #.#.#.###.#.#.#
        #.....#...#.#.#
        #.###.#.#.#.#.#
        #S..#.....#...#
        ###############
        """
        // rawInput = """
        // #################
        // #...#...#...#..E#
        // #.#.#.#.#.#.#.#.#
        // #.#.#.#...#...#.#
        // #.#.#.#.###.#.#.#
        // #...#.#.#.....#.#
        // #.#.#.#.#.#####.#
        // #.#...#.#.#.....#
        // #.#.#####.#.###.#
        // #.#.#.......#...#
        // #.#.###.#####.###
        // #.#.#...#.....#.#
        // #.#.#.#####.###.#
        // #.#.#.........#.#
        // #.#.#.#########.#
        // #S#.............#
        // #################
        // """

    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day16") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    // guard #available(macOS 13, *) else {fatalError("bruh")}

    let map = Map(rawInput)

    return map
}



func daySixteen_partOne() {
    let map = parseInput(useTestCase: false)
    let optimalPath = map.findBestPath()
    print(optimalPath.cost)
}

func daySixteen_partTwo() {
    let map = parseInput(useTestCase: true)
    let optimalPaths = map.findAllBestPaths()
    print(optimalPaths.count)
    let simulations = optimalPaths.map {map.simulate(sequence: $0)}
    let keySpots = simulations.reduce(Set<Vec>()) { (acc, val) in
        acc.union(Set(val.map{$0.pos}))
    }
    print(keySpots.count)
}