import Foundation

fileprivate let numeric = "0123456789+-"
fileprivate func mod(_ a: Int, _ b: Int) -> Int {
    // Returns an integer `d` in [0, b) such that there exists an int `c`
    // which satisfies b*c + d = a
    if a >= 0 {
        return a % b
    }

    return (a + b * (-a/b + 1)) % b
}

fileprivate struct Vec: Hashable, Equatable, Comparable {
    var x: Int, y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    static func +(lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    static func -(lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.x - rhs.x, lhs.y - rhs.y)
    }
    static func *(lhs: Vec, rhs: Int) -> Vec {
        return Vec(lhs.x * rhs, lhs.y * rhs)
    }

    static func %(lhs: Vec, rhs: Vec) -> Vec {
        return Vec(mod(lhs.x,rhs.x), mod(lhs.y,rhs.y))
    }

    static func +=(self: inout Vec, other: Vec) {
        self.x += other.x
        self.y += other.y
    }

    static func -=(self: inout Vec, other: Vec) {
        self.x -= other.x
        self.y -= other.y
    }

    static func %=(self: inout Vec, other: Vec) {
        self.x = mod(self.x, other.x)
        self.y = mod(self.y, other.y)
    }

    static func *=(self: inout Vec, other: Int) {
        self.x *= other
        self.y *= other
    }

    static func >(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.x > rhs.x && lhs.y > rhs.y
    }

    static func <(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.x < rhs.x && lhs.y < rhs.y
    }

    static func >=(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.x >= rhs.x && lhs.y >= rhs.y
    }
    static func <=(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.x <= rhs.x && lhs.y <= rhs.y
    }

    static func ==(lhs: Vec, rhs: Vec) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}


fileprivate class Robot {
    // Demo has height 7 and width 11
    static let arenaDims = Vec(101, 103)
    // static let arenaDims = Vec(11, 7)  // stored as width, height
    var pos: Vec, v: Vec

    init(_ pos: Vec, _ vel: Vec) {
        self.pos = pos
        self.v = vel
    }

    func step() {
        pos += v
        pos %= Robot.arenaDims
    }
}

fileprivate func parseInput(useTestCase: Bool) -> [Robot]{
    let rawInput: String
    if useTestCase {
        rawInput = """
        p=0,4 v=3,-3
        p=6,3 v=-1,-3
        p=10,3 v=-1,2
        p=2,0 v=2,-1
        p=0,0 v=1,3
        p=3,0 v=-2,-2
        p=7,6 v=-1,-3
        p=3,0 v=-1,-2
        p=9,3 v=2,3
        p=7,3 v=-1,2
        p=2,4 v=2,-3
        p=9,5 v=-3,-3
        """
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day14") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    let lines = rawInput.split(separator: "\n")
    var robots: [Robot] = []

    for line in lines {
        let comps = line.components(separatedBy: .whitespaces)
        let pos = comps[0].components(separatedBy: ",").map{$0.filter{numeric.contains($0)}}
        let vel = comps[1].components(separatedBy: ",").map{$0.filter{numeric.contains($0)}}

        let posVec = Vec(Int(pos[0])!, Int(pos[1])!)
        let velVec = Vec(Int(vel[0])!, Int(vel[1])!)
        robots.append(Robot(posVec, velVec))
    }

    return robots
}


fileprivate func makeGrid(_ robots: [Robot]) -> [[Int]]{
    var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: Robot.arenaDims.x), count: Robot.arenaDims.y)

    for r in robots {
        let p = r.pos
        grid[p.y][p.x] += 1
    }

    return grid
}

fileprivate func countQuadrants(_ grid: [[Int]]) -> [Int] {
    var quads = [0, 0, 0, 0]

    let (width, height) = (Robot.arenaDims.x, Robot.arenaDims.y)
    
    for i in 0..<height {
        guard i != height / 2  else {continue}
        for j in 0..<width {
            guard j != width / 2  else {continue}

            let quad = ((i <= height / 2) ? 0 : 2) + ((j <= width / 2) ? 0: 1)
            quads[quad] += grid[i][j]
        }
    }

    return quads
}

fileprivate func helper_printGrid(_ robots: [Robot]) {
    let grid = makeGrid(robots)
    // Print it
    for row in grid {
        let cols = row.map { ($0 == 0) ? " ." : String(format: "% 2d", $0) }.joined(separator: " ")
        print(cols)
    }
}

fileprivate class Pairs<T>: IteratorProtocol, Sequence {
    let data: [T]

    var i: Int = 0
    var j: Int = 1

    init(_ data: [T]) {
        self.data = data
    }

    func next() -> (T, T)? {
        guard data.count > 1 else {return nil}
        guard i < data.count - 1 else {
            return nil
        }

        let result = (data[i], data[j])
        j += 1
        if j >= data.count {
            i += 1
            j = i + 1
        }

        return result
    }
}

fileprivate struct Line: Hashable {
    let dx: Int, dy: Int, x0: Int, y0: Int

    init(_ a: Vec, _ b: Vec) {
        let diff: Vec
        if a.x > b.x {
            diff = a - b
        } else {
            diff = b - a
        }

        // Diff always has nonnegative x

        var canonicalPt = a
        while (canonicalPt - diff) >= Vec(0, 0) && (canonicalPt - diff) < Robot.arenaDims {
            canonicalPt -= diff
        }

        self.dx = diff.x
        self.dy = diff.y
        self.x0 = canonicalPt.x
        self.y0 = canonicalPt.y
    }
}

fileprivate func longestLine(_ points: [Vec]) -> Int {
    let pts = Set(points)
    var visited: Set<Line> = []

    var longestLine = 2

    for (a, b) in Pairs(points) {
        guard (a.x != b.x) || (a.y != b.y) else {continue}
        guard abs(a.x - b.x) < 2 else { continue }
        guard abs(a.y - b.y) < 2 else { continue }
        guard !(visited.contains(Line(a,b))) else {continue}
        var lineLen = 2
        let diff = b-a  // vec from a to b
        visited.insert(Line(a, b))
        var c = a
        while pts.contains(c - diff){
            c -= diff
            lineLen += 1
        }

        var d = b
        while pts.contains(d + diff){
            lineLen += 1
            d += diff
        }

        if lineLen > longestLine {
            longestLine = lineLen
        }
    }
    return longestLine
}


func dayFourteen_portOne() {
    let robots = parseInput(useTestCase: false)

    for _ in 0..<100 {
        for r in robots {
            r.step()
        }
    }

    let quads = countQuadrants(makeGrid(robots))
    print("Safety factor: \(quads.reduce(1, *))")
}


func dayFourteen_partTwo() {
    let robots = parseInput(useTestCase: false)
    var prevLongest = 0

    for stepNo in 0..<20000 {
        let longest = longestLine(robots.map{$0.pos})
        if longest > prevLongest {
            prevLongest = longest
            print("Step \(stepNo): \(longestLine(robots.map{$0.pos}))")
        }
        for r in robots {
            r.step()
        }
    }
}