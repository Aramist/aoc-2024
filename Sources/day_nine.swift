import Foundation


fileprivate func parseInput(useTestCase: Bool) -> [Int] {
    let rawInput: String
    if useTestCase {
        rawInput = "2333133121414131402"
        // rawInput = "1434564"  // "0....111....22222......33333"
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day9") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    let digits = "0123456789"

    return rawInput.filter { digits.contains($0 )}.map {  $0.wholeNumberValue! }
}

func cumulativeSum(_ arr: [Int]) -> [Int] {
    var result: [Int] = [arr[0]]

    var sum = arr[0]

    for i in 1..<arr.count {
        sum += arr[i]
        result.append(sum)
    }
    return result
}

fileprivate func checksum(_ disk: [Int]) -> Int {
    return disk.enumerated().reduce(0) { (acc, pair) in 
        let (idx, val) = pair
        return acc + idx * val
    }
}

fileprivate func makeDisk(fromCompressed comp: [Int]) -> [Int] {
    // let totalLen = comp.reduce(0, +)
    var disk: [Int] = []
    
    // comp[0] is first file
    // comp[1] is first blank
    // comp[2] is second file
    // etc...
    // even indices are file blocks
    // End index of last file block in indices
    let lastFile = (comp.endIndex % 2 == 1) ? comp.endIndex - 1: comp.endIndex - 2

    var (lpointer, rpointer) = (0, lastFile)
    // Amount of elements from R pointer used up in previous iterations
    var rconsumed = 0

    while lpointer < rpointer {
        let nLFile = comp[lpointer]
        var nLBlank = comp[lpointer+1]

        disk.append(contentsOf: Array(repeating: lpointer / 2, count: nLFile))
        

        // Fill the left blank space with elements from the right file block until one of the blocks is exhausted
        while nLBlank > 0 {
            guard rpointer > lpointer else { break }
            let nRFile = comp[rpointer]
            let nRAvail = nRFile-rconsumed


            // Case 1: nRFile > nLBlank
            // Result: nLBlank -> 0, rconsumed -> nonzero, move lpointer and break inner loop
            // Case 2: nRFile == nLBlank
            // Result: nLBlank -> 0, rconsumed -> 0 (reset), move lpointer and break
            // Case 3: nRFile < nLBlank
            // Result: nLBlank -> nonzero, rconsumed -> 0 (reset), move rpointer and continue

            if nRAvail <= nLBlank {  // Case 3 and 2
                disk.append(contentsOf: Array(repeating: rpointer / 2, count: nRAvail))
                nLBlank -= nRAvail
                rconsumed = 0
                rpointer -= 2
            } else {  // Case 1
                disk.append(contentsOf: Array(repeating: rpointer / 2, count: nLBlank))
                rconsumed += nLBlank
                nLBlank = 0
            }
        }
        lpointer += 2
    }
    // Ensure none are left over
    if lpointer == rpointer && rconsumed < comp[rpointer] {
        disk.append(contentsOf: Array(repeating: rpointer / 2, count: comp[rpointer] - rconsumed))
    }

    return disk
}


func makeDisk_partTwo(fromCompressed comp: [Int]) -> [Int]{
    // comp[0] is first file
    // comp[1] is first blank
    // comp[2] is second file
    // etc...
    // even indices are file blocks
    // End index of last file block in indices

    // 0 1 2 3 4, count = 5
    // 1, 3, 5

    let cumIndices = cumulativeSum([0] + comp)
    var blanks: [(Int, Int)] = []
    for i in stride(from: 1, to: comp.count, by: 2) {
        blanks.append((cumIndices[i], cumIndices[i+1]))
    }

    let lastFile = (comp.endIndex % 2 == 1) ? comp.endIndex - 1: comp.endIndex - 2

    var rpointer = lastFile

    func findInsertionIndex(rpointer ridx: Int) -> Int? {
        // Returns an index into the blanks array

        for i in 0..<blanks.count {
            if blanks[i].0 >= cumIndices[ridx] { return nil }
            let numBlanks = blanks[i].1 - blanks[i].0
            if (numBlanks >= comp[ridx]) || (i == blanks.count - 1)  {
                return i
            }
        }
        return nil
    }

    var fills: [(Int, Int, Int)] = [(0, 0, comp[0])]
    while rpointer > 1 {  // Never have to consider moving the first file
        let nRFile = comp[rpointer]  // number of spaces required to move right file
        if let insertIndex = findInsertionIndex(rpointer: rpointer) {
            fills.append((blanks[insertIndex].0, rpointer / 2, nRFile))
            if nRFile >= blanks[insertIndex].1 - blanks[insertIndex].0 {
                blanks.remove(at: insertIndex)
            } else {
                blanks[insertIndex].0 += nRFile
            }
        } else {
            fills.append((cumIndices[rpointer], rpointer / 2, nRFile))
        }

        rpointer -= 2
    }

    let lastFill = fills.max { $0.0 < $1.0 }!
    let diskSize = lastFill.0 + lastFill.2
    var disk: [Int?] = Array(repeating: nil, count: diskSize)
    for (start, val, len) in fills{
        for i in start..<start+len {
            disk[i] = val
        }
    }

    return disk.map{ (_ e: Int?) -> Int in
        e ?? 0
    }
}


func dayNine_partOne() {
    let compressedDisk = parseInput(useTestCase: false)
    let disk = makeDisk(fromCompressed: compressedDisk)
    let checksumVal = checksum(disk)
    print(checksumVal)
}


func dayNine_partTwo() {
    let compressedDisk = parseInput(useTestCase: false)
    let disk = makeDisk_partTwo(fromCompressed: compressedDisk)
    let checksumVal = checksum(disk)
    print(checksumVal)
}


// print("Day nine, part one")
// dayNine_partOne()

// print("Day nine, part two")
// dayNine_partTwo()
