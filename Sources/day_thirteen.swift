import Foundation
import Accelerate

fileprivate struct Vec: Hashable {
    let x: Int
    let y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    func dot(_ other: Vec) -> Int {
        return x * other.x + y * other.y
    }

    static func +(lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    static func -(lhs: Vec, rhs: Vec) -> Vec {
        return Vec(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    static func *(lhs: Vec, rhs: Int) -> Vec {
        return Vec(lhs.x * rhs, lhs.y * rhs)
    }

}

fileprivate struct Mat: Equatable, CustomStringConvertible {
    static func I(_ n: Int) -> Mat {
        var data: [[Double]] = []
        for i in 0..<n{
            var row: [Double] = Array(repeating: 0.0, count: n)
            row[i] = 1.0
            data.append(row)
        }
        return Mat(data)
    }
    static func zeros(_ dims: (m: Int, n: Int)) -> Mat{
        var data: [[Double]] = []

        for _ in 0..<dims.m{
            data.append(Array(repeating: 0, count: dims.n))
        }

        return Mat(data)
    }

    var data: [[Double]]  // TODO: use stride
    let dims: (Int, Int)

    var shape: (Int, Int) {
        get{ dims }
    }

    init(_ data: [[Double]]) {
        guard data.count > 0 else {fatalError("No empty matrices allowed")}
        let (m, n) = (data.count, data[0].count)
        for i in 0..<m {
            guard data[i].count == n else { fatalError("Matrix is not rectangular")}
        }

        self.data = data
        self.dims = (m, n)
    }

    subscript (row: Int, col: Int) -> Double { 
        get {
            guard row >= 0 && row < dims.0 && col >= 0 && col < dims.1 else {
                fatalError("Invalid Index")
            }
            return data[row][col]
        }
        set {
            guard row >= 0 && row < dims.0 && col >= 0 && col < dims.1 else {
                fatalError("Invalid Index")
            }
            data[row][col] = newValue
        }
    }


    func isUpperTriangular() -> Bool {
        for i in 1..<data.count {
            for j in 0..<min(i,data[0].count) {
                guard self[i,j] != 0 else { return false}
            }
        }
        return true
    }

    mutating func swapRows(_ a: Int, _ b: Int) {
        guard a >= 0 && b >= 0 && a < dims.0 && b < dims.0 else {
            fatalError("Invalid indices")
        }

        self.data.swapAt(a, b)
    }

    func LU() -> (P: Mat, L: Mat, U: Mat) {
        var P = Mat.I(dims.0)
        var L = Mat.I(dims.0)
        var U = self

        for i in 1..<dims.0 {
            // ensure U[i, i] is nonzero
            for swapIdx in i..<dims.0 {
                if abs(U[swapIdx, 0]) > 1e-5 {
                    P.swapRows(i, swapIdx)
                    U.swapRows(i, swapIdx)
                    break
                }
            }
            if abs(U[i, i]) < 1e-5 {
                fatalError("Sigular matrix?")
            }
            for j in 0..<i {
                // Make entry `j` in row `i` of U equal to 0
                // factor by which row j is multiplied to cancel out row i
                let prevRowScale = -U[i,j] / U[j, j]
                for k in j..<dims.1 {
                    U[i,k] += U[j,k] * prevRowScale
                }

                L[i,j] = -prevRowScale
            }
        }

        return (P: P, L: L, U: U)
    }


    var description: String {
        let components = data.map {
            "[" + $0.map{String($0)}.joined(separator: ", ") + "]"
        }.joined(separator: ",\n")
        return "[\(components)]"
    }


    var T: Mat {
        var result = Mat.zeros((self.dims.1, self.dims.0))

        for i in 0..<dims.0{
            for j in 0..<dims.1 {
                result[j,i] = self[i,j]
            }
        }
        return result
    }


    static func ==(lhs: Mat, rhs: Mat) -> Bool {
        return lhs.data == rhs.data
    }

    static func +(lhs: Mat, rhs: Mat) -> Mat {
        guard lhs.dims == rhs.dims else {
            fatalError("Matrices must have same dimensions to add")
        }

        var result: Mat = Mat.zeros(lhs.dims)
        for i in 0..<lhs.dims.0 {
            for j in 0..<lhs.dims.1 {
                result[i,j] = lhs[i,j] + rhs[i,j]
            }
        }
        return result
    }

    static func -(lhs: Mat, rhs: Mat) -> Mat {
        guard lhs.dims == rhs.dims else {
            fatalError("Matrices must have same dimensions to add")
        }

        var result: Mat = Mat.zeros(lhs.dims)
        for i in 0..<lhs.dims.0 {
            for j in 0..<lhs.dims.1 {
                result[i,j] = lhs[i,j] - rhs[i,j]
            }
        }
        return result
    }

    static func *(lhs: Mat, rhs: Mat) -> Mat {
        let (ldims, rdims) = (lhs.dims, rhs.dims)
        guard ldims.1 == rdims.0 else { fatalError("Incompatible dimensions for matmul")}

        let outDims = (ldims.0, rdims.1)
        var result = Mat.zeros(outDims)

        for i in 0..<outDims.0 {
            for j in 0..<outDims.1 {
                for k in 0..<ldims.1{
                    result[i,j] += lhs[i,k] * rhs[k,j]
                }
            }
        }
        return result
    }
}

fileprivate func invertLowerTriangular(_ ltri: Mat) -> Mat {
    var result = Mat.zeros(ltri.dims)

    for i in 0..<ltri.dims.0 { 
        for j in 0..<i {
            // Dot product computed up through row j-1 
            let partialSum = stride(from: 0, to: i, by: 1).reduce(Double(0)) { (acc, k) in
                acc + ltri[i,k] * result[k, j]
            }
            result[i, j] = -partialSum / ltri[i,i]
        }
        result[i, i] = 1/ltri[i,i]

    }

    return result
}

fileprivate func solveLinear(_ A: Mat, _ b: Mat) -> Mat {
    // PA = LU  =>  PAx = LUx  => P^-1B = LUx
    let (P, L, U) = A.LU()

    let bPerm = P.T * b
    let bMod = invertLowerTriangular(L) * bPerm
    // Ux = bMod
    var x = Mat.zeros((m: A.dims.0, n: 1))
    for i in stride(from: x.shape.0-1, to: -1, by: -1) {
        let partialSum = stride(from: x.shape.0-1, to: i, by: -1).reduce(Double(0)){ (acc, j) in 
            acc + U[i,j] * x[j,0]
        }
        // partialSum + U[i,i]*x[i] = b[i]
        x[i, 0] = (bMod[i, 0] - partialSum) / U[i,i]
    }
    return x
}

fileprivate struct Game {
    let da: Vec
    let db: Vec
    let prize: Vec

    func nonIntegerSolve() -> Vec? {
        // Case 1: is the system underdetermined?
        let determinant = da.x*db.y - da.y*db.x
        if determinant == 0 {
            // Underdetermined system, see if it is solvable
            if da.x < db.x || da.y < db.y {
                guard prize.x % da.x == 0 && prize.y == da.y * prize.x / da.x else { return nil }
            } else {
                guard prize.x % db.x == 0 && prize.y == db.y * prize.x / db.x else { return nil }
            }
        }

        // System should be solvable, solve and find integer solns

        // f(x1, x2) = 3x1 + x2
        // g1(x1, x2) = da1*x1 + db1*x2 - p1 = 0
        // g2(x1, x2) = da2*x1 + db2*x2 - p2 = 0
        // grad(x1) -> da1 * L1 + da2 * L2 = -3
        // grad(x2) -> db1 * L2 + db2 * L2 = -1

        
        let b = Mat([[Double(prize.x), Double(prize.y), -3, -1]]).T
        let A = Mat([
            [Double(da.x), Double(db.x), 0, 0],
            [Double(db.x), Double(db.y), 0, 0],
            [0, 0, Double(da.x), Double(da.y)],
            [0, 0, Double(db.x), Double(db.y)]
        ])
        let soln = solveLinear(A, b)
        return Vec(Int(soln[0,0]), Int(soln[1,0]))
    }

    /// Brute force BFS solution
    func solve() -> Vec? {
        // Vectors of # button presses
        guard let startPoint = nonIntegerSolve() else {return nil}
        var visited: Set<Vec> = []
        var feasible: [Vec] = []
        var queue: Set<Vec> = [startPoint]

        while !queue.isEmpty {
            let curPresses = queue.removeFirst()
            guard curPresses.x >= 0 && curPresses.y >= 0 else { continue }
            guard !visited.contains(curPresses) else { continue }
            visited.insert(curPresses)
            guard abs(curPresses.x - startPoint.x) < 100 && abs(curPresses.y - startPoint.y) < 100 else {continue}
            let curPos = Vec(da.x * curPresses.x + db.x * curPresses.y, da.y * curPresses.x + db.y * curPresses.y)

            let left = curPresses + Vec(-1, 0)
            let down = curPresses + Vec(0, -1)
            queue.insert(left)
            queue.insert(down)
            guard curPos.x <= prize.x && curPos.y <= prize.y else {
                continue
            }

            if curPos == prize {
                feasible.append(curPresses)
                continue
            }

            let up = curPresses + Vec(0, 1)
            let right = curPresses + Vec(1, 0)
            queue.insert(up)
            queue.insert(right)
        }

        if feasible.isEmpty { return nil }
        let c = Vec(3,1)
        return feasible.min { $1.dot(c) > $0.dot(c) }
    }
}

fileprivate func parseVec(_ str: String) -> Vec {
    let components = str.components(separatedBy: ",")
    // Filter out everything except digits and +-
    let goodChars = "0123456789+-"
    let x = Int(components[0].filter { goodChars.contains($0) })!
    let y = Int(components[1].filter { goodChars.contains($0) })!
    return Vec(x, y)
}

fileprivate func parseInput(useTestCase: Bool) -> [Game]{
    let rawInput: String
    if useTestCase {
        rawInput = """
        Button A: X+94, Y+34
        Button B: X+22, Y+67
        Prize: X=8400, Y=5400

        Button A: X+26, Y+66
        Button B: X+67, Y+21
        Prize: X=12748, Y=12176

        Button A: X+17, Y+86
        Button B: X+84, Y+37
        Prize: X=7870, Y=6450

        Button A: X+69, Y+23
        Button B: X+27, Y+71
        Prize: X=18641, Y=10279
        """
    } else {
        if let fileData = try? String(contentsOfFile: "/Users/atanelus/Downloads/input_day13") {
            rawInput = fileData
        } else {
            fatalError("Cannot open file")
        }
    }

    let lines = rawInput.split(separator: "\n")

    var games: [Game] = []

    for i in stride(from: 0, to: lines.count, by: 3) {
        let lineA = lines[i].components(separatedBy: ":").last!
        let lineB = lines[i + 1].components(separatedBy: ":").last!

        let linePrize = lines[i + 2].components(separatedBy: ":").last!

        let buttonA = parseVec(lineA)
        let buttonB = parseVec(lineB)
        let prize = parseVec(linePrize)
        let reprGame = Game(da: buttonA, db: buttonB, prize: prize)
        games.append(reprGame)
    }   

    return games
}


func dayThirteen_partOne() {
    let games = parseInput(useTestCase: false)

    let totalCost = games.reduce(0) { (acc, g) in
        guard let soln = g.solve() else {return acc}
        return acc + soln.dot(Vec(3, 1))
    }
    print(totalCost)
} 


func dayThirteen_partTwo() {
    let smallGames = parseInput(useTestCase: true)
    let games = smallGames.map {
        Game(da: $0.da, db: $0.db, prize: $0.prize + Vec(10000000000000, 10000000000000))
    }

    let totalCost = games.reduce(0) { (acc, g) in
        guard let soln = g.solve() else {return acc}
        return acc + soln.dot(Vec(3, 1))
    }
    print(totalCost)
}