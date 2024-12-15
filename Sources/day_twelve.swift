import Foundation

fileprivate func parseInput(useTestCase: Bool) -> [[Character]] {
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
        ABBAAA
        AAAAAA
        """
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day12") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    return rawInput.split(separator: "\n").map { Array($0) }
}

fileprivate struct Vec: Hashable {
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


}

fileprivate enum Direction: CaseIterable {
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
}

fileprivate class Region: Equatable {
    let id: Character
    let plots: Set<Vec>
    var externalEdges = 0
    var interiorEdges = 0
    var boundaryPlots: Set<Vec> = []
    weak var garden: Garden?

    init(id: Character, plots: any Sequence<Vec>, parent: Garden) {
        self.id = id
        self.plots = Set(plots)
        self.garden = parent
        self.externalEdges = computeNumExternalEdges()
    }

    var area: Int {
        plots.count
    }

    var perimeter: Int {
        plots.reduce(0) { (acc, plot) in 
            return acc + Direction.allCases.reduce(0) { (acc2, dir) in 
                let neighborPos = plot + dir
                return plots.contains(neighborPos) ? acc2 : acc2 + 1
            }
        }
    }

    func computeNumExternalEdges() -> Int {
        var numEdges = 0

        // Find a corner plot
        var curPlot = plots.randomElement()!
        
        while plots.contains(curPlot + .N) || plots.contains(curPlot + .W) {
            if plots.contains(curPlot + .N) {
                curPlot = curPlot + .N
            } else {
                curPlot = curPlot + .W
            }
        }
        // Now working on a north-west corner plot
        // Starting on the northern edge, travel east
        let startPlot = curPlot
        let startEdge: Direction = .N
        var travelDirection: Direction = .E

        repeat {
            boundaryPlots.insert(curPlot)
            let nextPlot = curPlot + travelDirection
            if !plots.contains(nextPlot) {  // this case always leads to a new edge becasue we don't count diagonal adjacency
                numEdges += 1
                travelDirection = travelDirection.right()
            } else if plots.contains(nextPlot + travelDirection.left()) {
                curPlot = nextPlot + travelDirection.left()
                travelDirection = travelDirection.left()
                numEdges += 1
            } else {
                curPlot = nextPlot
            }
        } while !(curPlot == startPlot && travelDirection.left() == startEdge)

        return numEdges
    }

    func contains(_ element: Vec) -> Bool {
        plots.contains(element)
    }

    func getInterior() -> Set<Vec> {
        var visited: Set<Vec> = []
        let start = plots.randomElement()!
        var toVisit: [Vec] = [start]
        
        guard let garden = self.garden else {
            fatalError("Garden is nil")
        }

        while !toVisit.isEmpty {
            let curPos = toVisit.removeFirst()
            visited.insert(curPos)

            for dir in Direction.allCases {
                let neighborPos = curPos + dir
                guard garden.posIsValid(neighborPos) else {continue}
                guard !visited.contains(neighborPos) else {continue}
                guard !boundaryPlots.contains(neighborPos) else {continue}
                toVisit.append(neighborPos)
            }
        }
        
        return visited
    }

    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.id == rhs.id && lhs.plots == rhs.plots
    }
}

fileprivate struct Hierarchy {
    let node: Region?
    var children: [Hierarchy]

    init(node: Region?, children: [Hierarchy]) {
        self.node = node
        self.children = children
    }

    var isLeaf: Bool { children.isEmpty }
}

fileprivate class Garden {
    let plots: [[Character]]
    var regions: [Region] = []
    let dims: (Int, Int)

    init(plots: [[Character]]) {
        self.plots = plots
        self.dims = (plots.count, plots[0].count)
        self.compute_regions()
    }

    func compute_regions() {
        var allVisited: Set<Vec> = []
        for i in 0..<dims.0{
            for j in 0..<dims.1 {
                let curPos = Vec(i, j)
                guard !allVisited.contains(curPos) else {
                    continue
                }

                let region = getRegion(forPos: curPos, withVisited: &allVisited)
                regions.append(region)
            }
        }
    }

    func posIsValid(_ pos: Vec) -> Bool {
        return pos.i >= 0 && pos.i < dims.0 && pos.j >= 0 && pos.j < dims.1
    }

    func at(_ pos: Vec) -> Character {
        return plots[pos.i][pos.j]
    }

    func getRegion(forPos pos: Vec, withVisited visited: inout Set<Vec>) -> Region {
        var regionPlots: Set<Vec> = []
        var toVisit: [Vec] = [pos]
        while !toVisit.isEmpty {
            let currentPos = toVisit.removeFirst()
            guard !visited.contains(currentPos) else {
                continue
            }
            visited.insert(currentPos)
            regionPlots.insert(currentPos)
            for dir in Direction.allCases {
                let neighborPos = currentPos + dir
                guard posIsValid(neighborPos) else { continue }
                if self.at(neighborPos) == self.at(currentPos) {
                    toVisit.append(neighborPos)
                }
            }
        }

        return Region(id: self.at(pos), plots: regionPlots, parent: self)
    }

    func makeHierarchy() -> Hierarchy{
        var root = Hierarchy(node: nil, children: [])
        

        return root
    }
}


func dayTwelve_partOne() {
    let plots = parseInput(useTestCase: false)
    let garden = Garden(plots: plots)


    let price = garden.regions.reduce(0) { (acc, region) in
        acc + region.area * region.perimeter
    }
    print(price)
}


func dayTwelve_partTwo() {
    let plots = parseInput(useTestCase: false)
    let garden = Garden(plots: plots)

    let price = garden.regions.reduce(0) { (acc, region) in
        acc + region.area * region.externalEdges
    }

    print(price)
}