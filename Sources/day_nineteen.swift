import Foundation


class PartOneSolver {
    var impossible: Set<Substring> = []
    var possible: Set<Substring> = []
    let vocabulary: [String]

    init(vocab: [String]) {
        self.vocabulary = vocab.sorted().reversed()
    }

    func combinationIsPossible(_ pattern: Substring) -> Bool {
        guard pattern != "" else { return true }
        guard !possible.contains(pattern) else {
            print("cache hit")
            return true
        }
        guard !impossible.contains(pattern) else {
            print("cache dit")
            return false
        }

        for v in vocabulary {
            if pattern.starts(with: v) {
                let valid = combinationIsPossible(pattern.dropFirst(v.count))
                if valid {
                    possible.insert(pattern)
                    return true
                }
            }
        }
        impossible.insert(pattern)
        return false
    }
}

class Solver {
    var cache: [Substring: Int] = [:]
    let vocabulary: [String]

    init(vocab: [String]) {
        self.vocabulary = vocab.sorted().reversed()
    }

    func numPossibleCombos(_ pattern: Substring) -> Int {
        guard pattern != "" else { return 1 }
        if let cacheHit = cache[pattern] {
            // print("cache hit")
            return cacheHit
        }

        var result = 0
        for v in vocabulary {
            if pattern.starts(with: v) {
                let extras = numPossibleCombos(pattern.dropFirst(v.count))
                result += extras
            }
        }

        cache[pattern] = result
        return result
    }
}

fileprivate func parseInput(useTestCase: Bool) -> (Solver, [String]) {
    let rawInput: String
    if useTestCase {
        rawInput = """
        r, wr, b, g, bwu, rb, gb, br

        brwrr
        bggr
        gbbr
        rrbgbr
        ubwu
        bwurrg
        brgr
        bbrgwb
        """
    } else {
        guard let fileCont = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day19") else {
            fatalError("Failed to read input fiel")
        }
        rawInput = fileCont
    }

    let split = rawInput.split(separator: "\n")
    let towels = split[0].split(separator: ",").map { $0.filter {$0 != " "} }
    let problems = split[1...].filter { $0.filter {$0 != " " && $0 != "\n"} != ""}.map { String($0) }

    return (Solver(vocab: towels), problems)
}


// func dayNineteen_partOne() {
//     let (solver, problems) = parseInput(useTestCase: false)

//     let sum = problems.reduce(0) { (acc, prob) in 
//         return acc + (solver.combinationIsPossible(prob[...]) ? 1 : 0)
//     }

//     print("Number of possible combinations: \(sum)")
// }

func dayNineteen_partTwo() {
    let (solver, problems) = parseInput(useTestCase: true)

    let sum = problems.reduce(0) { (acc, prob) in 
        return acc + solver.numPossibleCombos(prob[...])
    }

    print("Number of possible combinations: \(sum)")
}