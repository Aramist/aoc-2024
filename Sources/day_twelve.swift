import Foundation

fileprivate func parseInput(useTestCase: Bool) -> Garden {
    let rawInput: String
    if useTestCase {
        // rawInput = """
        // RRRRIICCFF
        // RRRRIICCCF
        // VVRRRCCFFF
        // VVRCCCJFFF
        // VVVVCJJCFE
        // VVIVCCJJEE
        // VVIIICJJEE
        // MIIIIIJJEE
        // MIIISIJEEE
        // MMMISSJEEE
        // """
        rawInput = """
        AAAAAA
        AAACCA
        AAACCA
        ABBAAA
        ABBADA
        AAAAAA
        """
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day12") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    let arr_2d = rawInput.split(separator: "\n").map { Array($0) }
    let shape = (arr_2d.count, arr_2d[0].count)
    let arr_1d = arr_2d.reduce([], +)
    return Garden(contents: arr_1d, shape: shape)
}

fileprivate struct Vec: Hashable, CustomStringConvertible {
    let i: Int
    let j: Int

    init(_ i: Int, _ j: Int) {
        self.i = i
        self.j = j
    }

    static func +(lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.i + rhs.i, lhs.j + rhs.j)
    }

    static func -(lhs: Vec, rhs: Vec) -> (Int, Int) {
        return (lhs.i - rhs.i, lhs.j - rhs.j)
    }

    static func +(lhs: Vec, rhs: Direction) -> Vec {
        return lhs + rhs.getDiff()
    }

    var description: String {
        return "(\(i), \(j))"
    }

}

fileprivate struct DirectedVec: Hashable, CustomStringConvertible {
    let vec: Vec
    let dir: Direction

    var description: String {
        "\(vec) \(dir)"
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

    var description: String {
        switch self {
        case .N: return "N"
        case .E: return "E"
        case .S: return "S"
        case .W: return "W"
        }
    }
}

fileprivate class Region: Equatable {
    let id: Character
    let plots: Set<Vec>
    var edgeCount: Int = 0
    var boundaryPlots: Set<DirectedVec> = []

    init(id: Character, plots: any Sequence<Vec>) {
        self.id = id
        self.plots = Set(plots)
        self.populateEdges()
    }

    var area: Int {
        get { plots.count }
    }

    var perimeter: Int {
        // Does edge detection
        plots.reduce(0) { (acc, plot) in 
        // For each plot, add 'x' to the accumulator where 'x' is the number of neighbors
        // to the plot that do not belong to self
            return acc + Direction.allCases.reduce(0) { (acc2, dir) in 
                // This reduce computes the number of neighbors that do not belong to self
                // by iterating over all directions
                let neighborPos = plot + dir
                return plots.contains(neighborPos) ? acc2 : acc2 + 1
            }
        }
    }

    func computeEdges(fromStartPoint start: Vec) -> Int {
        var numEdges = 0
        var curPlot = start

        // First make sure this is a boundary plot
        let numNeighbors = Direction.allCases.reduce(0) { (acc, dir) in
            return plots.contains(curPlot + dir) ? acc + 1 : acc
        }
        guard numNeighbors < 4 else { return 0 }

        // Now we know we are on a boundary plot, start marching
        // Determine which direction the edge is on
        let origEdgeDirection: Direction
        if !contains(curPlot + .N){
            origEdgeDirection = .N
        } else if !contains(curPlot + .E) {
            origEdgeDirection = .E
        } else if !contains(curPlot + .S) {
            origEdgeDirection = .S
        } else {
            origEdgeDirection = .W
        }
        guard !boundaryPlots.contains(DirectedVec(vec: start, dir: origEdgeDirection)) else {
            return 0
        }

        var edgeDirection = origEdgeDirection
        while true {
            boundaryPlots.insert(DirectedVec(vec: curPlot, dir: edgeDirection))
            let travelDirection = edgeDirection.right()
            // See if we can turn left to continue the clockwise traversal
            if contains(curPlot + edgeDirection) {
                numEdges += 1
                curPlot = curPlot + edgeDirection
                edgeDirection = edgeDirection.left()
            } else if !contains(curPlot + travelDirection) {
                // Otherwise, see if the way forward is empty and we need a right turn
                numEdges += 1
                edgeDirection = travelDirection
                // We don't update curPlot because it's possible that this is a 
                // 1-tile-wide corner
            } else {
                // No left turn available and we can go forward
                curPlot = curPlot + travelDirection
            }

            if (curPlot == start) && (edgeDirection == origEdgeDirection) {
                break
            }
        }
        // If the start point is at a corner, failing to check the edge direction can
        // lead to us not counting that last corner, as the loop exits one iteration early

        return numEdges
    }

    func populateEdges() {
        for plot in plots {
            // guard !boundaryPlots.contains(plot) else { continue }
            let edges = computeEdges(fromStartPoint: Vec(plot.i, plot.j))
            self.edgeCount += edges
        }
    }
    func contains(_ element: Vec) -> Bool {
        plots.contains(element)
    }

    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.id == rhs.id && lhs.plots == rhs.plots
    }
}

fileprivate class Garden {
    let plots: [Character]
    var regions: [Region] = []
    let shape: (Int, Int)

    init(contents plots: [Character], shape: (Int, Int)) {
        self.plots = plots
        self.shape = shape
        self.compute_regions()
    }

    func compute_regions() {
        var allVisited: Set<Vec> = []
        for i in 0..<shape.0{
            for j in 0..<shape.1 {
                let curPos = Vec(i, j)
                guard !allVisited.contains(curPos) else {
                    continue
                }

                let region = getRegion(forPos: curPos, withVisited: &allVisited)
                regions.append(region)
            }
        }
    }

    subscript(i: Int, j: Int) -> Character? {
        guard i >= 0 && i < shape.0 && j >= 0 && j < shape.1 else {
            return nil
        }

        let trueIdx = i * shape.0 + j
        return plots[trueIdx]
    }
    subscript(pos: Vec) -> Character? {
        return self[pos.i, pos.j]
    }

    func getRegion(forPos pos: Vec, withVisited visited: inout Set<Vec>) -> Region {
        var regionPlots: Set<Vec> = []
        var toVisit: [Vec] = [pos]
        guard let id = self[pos] else { fatalError("index out of bounds") }
        while !toVisit.isEmpty {
            let currentPos = toVisit.removeFirst()
            guard !visited.contains(currentPos) else {
                continue
            }
            visited.insert(currentPos)
            regionPlots.insert(currentPos)
            for dir in Direction.allCases {
                let neighborPos = currentPos + dir
                guard let neighborVal = self[neighborPos] else {continue}
                if neighborVal == self[currentPos] {
                    toVisit.append(neighborPos)
                }
            }
        }

        return Region(id: id, plots: regionPlots)
    }
}


func dayTwelve_partOne() {
    let garden = parseInput(useTestCase: false)


    let price = garden.regions.reduce(0) { (acc, region) in
        acc + region.area * region.perimeter
    }
    print(price)
}


func dayTwelve_partTwo() {
    let garden = parseInput(useTestCase: false)

    let price = garden.regions.reduce(0) { (acc, region) in
        print("Region \(region.id) has area \(region.area) and \(region.edgeCount) edges")

        return acc + region.area * region.edgeCount
    }

    print(price)
}
