import Foundation

func parseIntList(from data: String) -> [Int] {
    return data.split(separator: " ").compactMap { str in
        Int(str)
    }
}

func isMonotonous(_ list: [Int]) -> Bool {
    guard list.count > 1 else {
        return true
    }

    let increasing: Bool = list[1] > list[0]

    for i in 0..<list.count - 1 {
        if (list[i] < list[i+1]) != increasing {
            return false
        }
    }
    return true
}

func isSafe(_ list: [Int]) -> Bool {
    guard isMonotonous(list) else { return false }

    for i in 0..<list.count - 1 {
        let (l, r) = (list[i], list[i+1])
        let diff = abs(r - l)
        if (diff < 1) || (diff > 3) {return false}
    }
    return true
}

func dayTwo_partOne() {
    guard let data: String = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day2", encoding: .utf8) else {
        fatalError("Failed to read input file")
    }
    let reports = data.split(separator: "\n").compactMap { 
        String($0)
    }.map{ 
        parseIntList(from: $0)
    }

    let numSafe = reports.map{ isSafe($0) ? 1 : 0 }.reduce(0, +)
    print(numSafe)

}


func intDiff(_ list: [Int]) -> [Int] {
    guard list.count > 1 else { return [] }
    var diffs: [Int] = []
    for i in 0..<list.count - 1 {
        diffs.append(list[i+1] - list[i])
    }
    return diffs
}

func isSafe2(_ list: [Int]) -> Bool {
    if isSafe(list) { return true }
    if list.count == 1 { return false}
    if list.count == 2 { return true}

    // Attempt remaval of each element and test safety:
    for i in 0..<list.count {
        var copy = list
        copy.remove(at: i)
        if isSafe(copy) { return true }
    }
    return false
}
// func isSafe2(_ list: [Int]) -> Bool {
//     // Check to see if all but one differences are the same sign
//     let diffs = intDiff(list)
//     let numNeg = diffs.filter{ $0 < 0 }.count
//     let numPos = diffs.filter{ $0 > 0 }.count
//     let size = diffs.count

//     let isPos = numPos > numNeg

//     var i: Int = 0
//     var hasSkipped: Bool = false
//     while i < size {
//         let direction = ((diffs[i] > 0) && isPos) || ((diffs[i] < 0) && !isPos)
//         if direction && (abs(diffs[i]) >= 1) && (abs(diffs[i]) <= 3){
//             // good case
//             i += 1
//             continue
//         }
//         if hasSkipped {
//             return false
//         }
//         if i == size - 1 {  // skip last element
//             return true
//         }
//         let combDiff = (i==0) ? diffs[i+1] : diffs[i] + diffs[i+1]   // pretend to drop the i-th element
//         let combDirection = ((combDiff > 0) && isPos) || ((combDiff < 0) && !isPos)
//         if (abs(combDiff) >= 1) && (abs(combDiff) <= 3) && combDirection {
//             i += 2
//             hasSkipped = true
//             continue
//         }
//         return false
//     }
//     return true
// }

func dayTwo_partTwo() {
    guard let data: String = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day2", encoding: .utf8) else {
        fatalError("Failed to read input file")
    }
    let reports = data.split(separator: "\n").compactMap { 
        String($0)
    }.map{ 
        parseIntList(from: $0)
    }

    let numSafe = reports.filter{ isSafe2($0) }.count
    print(numSafe)
}