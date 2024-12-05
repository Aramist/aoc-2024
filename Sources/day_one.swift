import Foundation

func dayOne_partOne() {
    guard let data: String = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day1", encoding: .utf8) else {
        fatalError("Failed to read input file")
    }

    let listA: [Int] = data.split(separator: "\n").map{ Int($0.split(separator: " ")[0])!}
    let listB: [Int] = data.split(separator: "\n").map{ Int($0.split(separator: " ")[1])!}

    // commented part 1
    let sortedListA: [Int] = listA.sorted()
    let sortedListB: [Int] = listB.sorted()

    var diffSum = 0
    for (a, b) in zip(sortedListA, sortedListB) {
        diffSum += abs(b - a)
    }

    print(diffSum)
}

func dayOne_partTwo() {

    guard let data: String = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day1", encoding: .utf8) else {
        fatalError("Failed to read input file")
    }

    let listA: [Int] = data.split(separator: "\n").map{ Int($0.split(separator: " ")[0])!}
    let listB: [Int] = data.split(separator: "\n").map{ Int($0.split(separator: " ")[1])!}

    // part 2
    let setA = Set(listA)
    let filterB = listB.filter{ setA.contains($0)}

    let sum = filterB.reduce(0) { (result, element) -> Int in
        return result + element
    }

    print(sum)
}