import Foundation

func dayThreeDoMatching(_ data: String) -> Int {
    guard #available(macOS 13.0, *)  else {
        fatalError("need regex")
    }

    let filter = /mul\((?<numa>\d+)\,(?<numb>\d+)\)/
    var result = 0

    var str = data
    while let match = str.firstMatch(of: filter) {
        result += Int(match.numa)! * Int(match.numb)!

        // Drop the matched substring
        let range = str.startIndex..<match.range.upperBound
        str.removeSubrange(range)
    }
    return result
}

func dayThree_partOne() {

    guard let data: String = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day3", encoding: .utf8) else {
        fatalError("Failed to read input file")
    }


    let result = dayThreeDoMatching(data)
    print(result)
}



func dayThree_partTwo() {

    guard let data = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day3", encoding: .utf8) else {
        fatalError("Failed to read input file")
    }

    guard #available(macOS 13.0, *)  else {
        fatalError("need regex")
    }

    let doFilter = /do\(\)/
    let dontFilter = /don\'t\(\)/
    
    var grabbingText = true
    var dataSubset = data
    var filteredInput = ""

    while true {
        let filter = grabbingText ? dontFilter : doFilter
        guard let match = dataSubset.firstMatch(of: filter) else{
            // Grab remaining text and get out
            if grabbingText{
                filteredInput += dataSubset
            }
            break
        }

        if grabbingText {
            // Add the text before the match
            filteredInput += dataSubset[..<match.range.lowerBound]
        }
        dataSubset.removeSubrange(..<match.range.upperBound)
        grabbingText.toggle()
    }

    let result = dayThreeDoMatching(filteredInput)
    print(result)
}