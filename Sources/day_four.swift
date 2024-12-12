import Foundation

fileprivate enum Direction: CaseIterable {
    case N, NE, E, SE, S, SW, W, NW
    func getDiff() -> (Int, Int) {
        switch self {
        case .N: return (-1, 0)
        case .NE: return (-1, 1)
        case .E: return (0, 1)
        case .SE: return (1, 1)
        case .S: return (1, 0)
        case .SW: return (1, -1)
        case .W: return (0, -1)
        case .NW: return (-1, -1)
        }
    }
}

// struct Queue<T> {
//     var data: [T] = []
//     var startIndex: Int = 0
//     var endIndex: Int = 0
//     var isEmpty: Bool { return count == 0 }
//     var count: Int { 
//         if  endIndex >= startIndex{
//             return endIndex - startIndex
//         }
//         return endIndex - startIndex + data.count
//     }

//     mutating func push(_ data: T) {
//         if self.count == self.data.count {
//             self.data.insert(data, at: self.endIndex)
//             return
//         }
//         if self.endIndex == self.data.count {
//             self.endIndex = 0
//         }
//     }
// }

struct Wordsearch {
    var words: Array<Array<Character>>

    init(fromStrings data: [String]) {
        words = data.map{ Array($0) }
    }

    func countWords(_ target: String) -> Int {
        // Find the first letter candidates
        var candQueue: [((Int, Int), Direction, any StringProtocol)] = []
        for i in 0..<words.count{
            for j in 0..<words[0].count{
                if words[i][j] == target[target.startIndex]{
                    for d in Direction.allCases {
                        let (di, dj) = d.getDiff()
                        candQueue.append(((i+di,j+dj), d, target.dropFirst()))
                    }
                }
            }
        }

        // BFS
        var numFound: Int = 0
        while !candQueue.isEmpty {
            let ((i,j), dir, word) = candQueue.removeFirst()
            if word.isEmpty {
                numFound += 1
                continue
            }

            guard i >= 0 && i < words.count && j >= 0 && j < words[0].count else {
                continue  // out of bounds
            }

            guard words[i][j] == word[word.startIndex] else {
                continue  // not the desired letter
            }

            // Populate the queue with the next letter candidate
            let (di, dj) = dir.getDiff()
            candQueue.append(((i+di, j+dj), dir, word.dropFirst()))
        }
        return numFound
    }

    func isMas(_ i: Int, _ j: Int) -> Bool {
        guard i >= 1 && i < words.count - 1 && j >= 1 && j < words[0].count - 1 else {
            return false
        }

        guard words[i][j] == "A" else {
            return false
        }

        // Allow NW M and SE S or vice versa
        guard (words[i-1][j-1] == "M" && words[i+1][j+1] == "S") || (words[i-1][j-1] == "S" && words[i+1][j+1] == "M") else {
            return false
        }

        // Allow NE M and SW S or vice versa
        guard (words[i-1][j+1] == "M" && words[i+1][j-1] == "S") || (words[i-1][j+1] == "S" && words[i+1][j-1] == "M") else {
            return false
        }
        return true
    }

    func countMas() -> Int {
        var numMasFound = 0
        for i in 0..<words.count{
            for j in 0..<words[0].count{
                numMasFound += isMas(i, j) ? 1 : 0
            }
        }
        return numMasFound
    }
}

func dayFour_partOne() {
    guard let data: String = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day4", encoding: .utf8) else {
        fatalError("Failed to read input file")
    }

    // for testing, should return 18
    // let data = """
    // MMMSXXMASM
    // MSAMXMSMSA
    // AMXSXMAAMM
    // MSAMASMSMX
    // XMASAMXAMM
    // XXAMMXXAMA
    // SMSMSASXSS
    // SAXAMASAAA
    // MAMMMXMMMM
    // MXMXAXMASX
    // """
    let charArray = data.split(separator: "\n").map{ String($0) }

    let ws = Wordsearch(fromStrings: charArray)
    let numFound = ws.countWords("XMAS")
    print(numFound)

}

func dayFour_partTwo() {
    guard let data = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day4", encoding: .utf8) else {
        fatalError("Failed to read input file")
    }


    // for testing, should return 9
    // let data = """
    // MMMSXXMASM
    // MSAMXMSMSA
    // AMXSXMAAMM
    // MSAMASMSMX
    // XMASAMXAMM
    // XXAMMXXAMA
    // SMSMSASXSS
    // SAXAMASAAA
    // MAMMMXMMMM
    // MXMXAXMASX
    // """

    let ws = Wordsearch(fromStrings: data.split(separator: "\n").map{ String($0) })
    print(ws.countMas())
}

// func main() {
//     print("Day 4 part one")
//     dayFour_partOne()
//     print("Day 4 part two")
//     dayFour_partTwo()
// }
// main()














