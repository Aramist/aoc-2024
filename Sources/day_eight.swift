import Foundation

fileprivate struct Vec: Hashable, Equatable {
    let i: Int
    let j: Int

    init(_ pos: (Int, Int)) {
        self.i = pos.0
        self.j = pos.1
    }

    static func +(lhs: Vec, rhs: Vec) -> Vec {
        return Vec((lhs.i + rhs.i, lhs.j + rhs.j))
    }
    static func -(lhs: Vec, rhs: Vec) -> Vec {
        return Vec((lhs.i - rhs.i, lhs.j - rhs.j))
    }
    static func *(lhs: Vec, rhs: Int) -> Vec {
        return Vec((lhs.i * rhs, lhs.j * rhs))
    }
}

fileprivate func parseInput(useTestCase: Bool) -> [[Character]]{
    let rawInput: String
    if useTestCase {
        rawInput = """
            ............
            ........0...
            .....0......
            .......0....
            ....0.......
            ......A.....
            ............
            ............
            ........A...
            .........A..
            ............
            ............
            """
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day8") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    // Using components(separatedBy:) instead of split(separator:) causes empty lines to be returned
    let result = rawInput.components(separatedBy: .newlines).map { Array($0)}.filter { $0.count > 0 }
    return result
}


fileprivate class Pairwise<T>: IteratorProtocol, Sequence {
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


func findAntinodes_portOne(map: [[Character]]) -> [(Int, Int)]{
    // Locate nodes in the map
    var nodes: [Character: [(Int, Int)]] = [:]

    for i in 0..<map.count {
        for j in 0..<map[0].count {
            guard map[i][j] != "." else {continue}
            let c = map[i][j]
            if let nodeLocations = nodes[c] {
                nodes[c] = nodeLocations + [(i,j)]
            }else {
                nodes[c] = [(i,j)]
            }
        }
    }

    func isValidLocation(_ location: (Int, Int)) -> Bool {
        return location.0 >= 0 && location.0 < map.count && location.1 >= 0 && location.1 < map[0].count
    }

    var antinodes: Set<Vec> = []
    for node in nodes.keys {
        let locations = nodes[node]!
        for (a, b) in Pairwise(locations) {
            let diff = (a.0 - b.0, a.1 - b.1) // b -> a vector
            let anodeA = (a.0 + diff.0, a.1 + diff.1)
            let anodeB = (b.0 - diff.0, b.1 - diff.1)
            if isValidLocation(anodeA) {
                antinodes.insert(Vec(anodeA))
            }
            if isValidLocation(anodeB) {
                antinodes.insert(Vec(anodeB))
            }
        }
    }

    return Array(antinodes).map { (_ p: Vec) -> (Int, Int) in
        return (p.i, p.j)
    }
}

func findAntinodes_portTwo(map: [[Character]]) -> [(Int, Int)]{
    // Locate nodes in the map
    var nodes: [Character: [(Int, Int)]] = [:]

    for i in 0..<map.count {
        for j in 0..<map[0].count {
            guard map[i][j] != "." else {continue}
            let c = map[i][j]
            if let nodeLocations = nodes[c] {
                nodes[c] = nodeLocations + [(i,j)]
            }else {
                nodes[c] = [(i,j)]
            }
        }
    }

    func isValidLocation(_ location: Vec) -> Bool {
        return location.i >= 0 && location.i < map.count && location.j >= 0 && location.j < map[0].count
    }

    var antinodes: Set<Vec> = []
    for node in nodes.keys {
        let locations = nodes[node]!
        for (a, b) in Pairwise(locations) {
            let va = Vec(a)
            let vb = Vec(b)
            let diff = va - vb  // b -> a vector

            var mult = 0
            var testPoint = va + diff * mult
            while isValidLocation(testPoint){
                antinodes.insert(testPoint)
                mult += 1
                testPoint = va + diff * mult
            }

            mult = 0
            testPoint = vb + diff * mult
            while isValidLocation(testPoint){
                antinodes.insert(testPoint)
                mult -= 1
                testPoint = vb + diff * mult
            }
        }
    }

    return Array(antinodes).map { (_ p: Vec) -> (Int, Int) in
        return (p.i, p.j)
    }
}

func dayEight_partOne() {
    let data = parseInput(useTestCase: true)
    let anodes = findAntinodes_portOne(map: data)
    print(anodes.count)
}

func dayEight_partTwo() {
    let data = parseInput(useTestCase: false)
    let anodes = findAntinodes_portTwo(map: data)
    print(anodes.count)
}



print("Day eight, part one")
dayEight_partOne()

print("Day eight, part two")
dayEight_partTwo()