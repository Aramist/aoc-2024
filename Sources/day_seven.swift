import Foundation

private func parseInput(useTestCase: Bool) -> [(Int, [Int])] {
    let rawInput: String
    if useTestCase {
        rawInput = """
            190: 10 19
            3267: 81 40 27
            83: 17 5
            156: 15 6
            7290: 6 8 6 15
            161011: 16 10 13
            192: 17 8 14
            21037: 9 7 18 13
            292: 11 6 16 20
            """
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day7") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    let lines = rawInput.components(separatedBy: .newlines)
    var result: [(Int, [Int])] = []
    for line in lines {
        guard line.contains(":") else { continue }
        let parts = line.components(separatedBy: ": ")
        guard let key = Int(parts[0]) else {
            fatalError("Cannot convert \(parts[0]) to Int")
        }
        guard let values = parts[1].components(separatedBy: " ").map({ Int($0) }) as? [Int] else {
            fatalError("Cannot convert \(parts[1]) to [Int]")
        }
        result.append((key, values))
    }
    return result
}

enum Operation {
    case add
    case mult
    case cat
}

func isValid(expectedResult expected: Int, withNums nums: [Int], withOps ops: [Operation]) -> Bool {
    if ops.count < nums.count - 1 {
        // Remove concatenation operation for part 1
        return isValid(expectedResult: expected, withNums: nums, withOps: ops + [.add])
            || isValid(expectedResult: expected, withNums: nums, withOps: ops + [.mult])
            || isValid(expectedResult: expected, withNums: nums, withOps: ops + [.cat])
    }

    var result = nums[0]
    for i in 0..<ops.count {
        switch ops[i] {
        case .add:
            result += nums[i + 1]
        case .mult:
            result *= nums[i + 1]
        case .cat:  // Remove this case for part 1
            let pow10 = Int(pow(10, 1.0 + floor(log10(Double(nums[i+1])))))
            result = result * pow10 + nums[i+1]
        }
    }
    return result == expected
}

func daySeven_partOne() {
    let input = parseInput(useTestCase: false)

    var sum = 0
    for (expectedResult, nums) in input{ 
        if isValid(expectedResult: expectedResult, withNums: nums, withOps: []) {
            sum += expectedResult
        }
    }
    print(sum)
}

func daySeven_partTwo() {
    let input = parseInput(useTestCase: false)

    var sum = 0
    for (expectedResult, nums) in input{ 
        if isValid(expectedResult: expectedResult, withNums: nums, withOps: []) {
            sum += expectedResult
        }
    }
    print(sum)
}


// print("Day 7, part 1")
// daySeven_partOne()

print("Day 7, part 2")
daySeven_partTwo()