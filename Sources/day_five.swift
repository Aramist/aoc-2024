import Foundation

struct RuleBook {
    let rules: [(Int, Int)]
    var compressedRules: [Int: [Int]] = [:]

    init(_ rules: [(Int, Int)]) {
        self.rules = rules

        for (left, right) in self.rules {
            if let leftList = self.compressedRules[left] {
                self.compressedRules[left] = leftList + [right]
            } else {
                self.compressedRules[left] = [right]
            }
        }
    }

    func listAdheresToRules(_ list: [Int]) -> Bool {
        for (l, r) in self.rules {
            // See if they are inside the list
            guard let leftIdx = list.firstIndex(of: l),
                  let rightIdx = list.firstIndex(of: r)
            else {
                continue
            }
            // Both are inside, check ordering
            if rightIdx < leftIdx {
                return false
            }
        }
        return true
    }

    func resort(_ pages: inout [Int]) {
        var i = 0
        var j = 1

        while i < pages.count {
            if j == pages.count {
                i += 1
                j = i+1
                continue
            }

            guard let isISmaller = self.compressedRules[pages[i]]?.contains(pages[j]) else {
                // No rules present for idx i
                j += 1
                continue
            }
            if !isISmaller {
                pages.swapAt(i, j)
            } else {
                j += 1
            }
        }
    }
}

func parseData(useTestData test: Bool) -> (RuleBook, [[Int]]){
    let data: String
    if test {
        data = """
        47|53
        97|13
        97|61
        97|47
        75|29
        61|13
        75|53
        29|13
        97|29
        53|29
        61|53
        97|53
        61|29
        47|13
        75|47
        97|75
        47|61
        75|61
        47|29
        75|13
        53|13

        75,47,61,53,29
        97,61,53,29,13
        75,29,13
        75,97,47,61,53
        61,13,29
        97,13,75,29,47
        """
    } else {
        data = try! String(contentsOfFile: "/Users/atanelus/Downloads/input_day5", encoding: .utf8)
    }
    
    // Parse input rules
    let splitData = data.split(separator: "\n")
    var rules: [(Int, Int)] = []
    var i = 0

    while splitData[i].contains("|") {
        let rule = splitData[i].split(separator: "|").map{ Int($0)!}
        rules.append((rule[0], rule[1]))
        i+=1
    }

    let queries = splitData[i...].map { $0.split(separator: ",").map{ Int($0)!}}

    return (RuleBook(rules), queries)
}

func dayFive_partOne() {
    // Parse input rules
    let (rules, queries) = parseData(useTestData: false)
    var sum = 0
    for query in queries {
        guard rules.listAdheresToRules(query) else {
            continue
        }
        let middle_idx = query.count / 2
        sum += query[middle_idx]
    }
    print(sum)
}

func dayFive_partTwo() {
    // Parse input rules
    let (rules, queries) = parseData(useTestData: false)
    var sum = 0
    for query in queries {
        guard !rules.listAdheresToRules(query) else {
            continue
        }
        var queryCopy = query
        rules.resort(&queryCopy)

        let middleIdx = queryCopy.count / 2
        sum += queryCopy[middleIdx]
    }
    print(sum)
}

// print("Day 5 part 1:")
// dayFive_partOne()
// print("Day 5 part 2:")
// dayFive_partTwo()