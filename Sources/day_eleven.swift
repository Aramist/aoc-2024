import Foundation

public struct PriorityQueue<T: Comparable> {
    
    fileprivate(set) var heap = [T]()
    private let ordered: (T, T) -> Bool
    
    /// Creates a new PriorityQueue using either the `>` operator or `<` operator to determine order.
    /// The default order is descending if `ascending` is not specified.
    ///
    /// - parameter ascending: Use the `>` operator (`true`) or `<` operator (`false`).
    /// - parameter startingValues: An array of elements to initialize the PriorityQueue with.
    public init(ascending: Bool = false, startingValues: [T] = []) {
        self.init(order: ascending ? { $0 > $1 } : { $0 < $1 }, startingValues: startingValues)
    }
    
    /// Creates a new PriorityQueue with the given custom ordering function.
    ///
    /// - parameter order: A function that specifies whether its first argument should
    ///                    come after the second argument in the PriorityQueue.
    /// - parameter startingValues: An array of elements to initialize the PriorityQueue with.
    public init(order: @escaping (T, T) -> Bool, startingValues: [T] = []) {
        ordered = order
        
        // Based on "Heap construction" from Sedgewick p 323
        heap = startingValues
        var i = heap.count/2 - 1
        while i >= 0 {
            sink(i)
            i -= 1
        }
    }
    
    /// How many elements the Priority Queue stores. O(1)
    public var count: Int { return heap.count }
    
    /// true if and only if the Priority Queue is empty. O(1)
    public var isEmpty: Bool { return heap.isEmpty }
    
    /// Add a new element onto the Priority Queue. O(lg n)
    ///
    /// - parameter element: The element to be inserted into the Priority Queue.
    public mutating func push(_ element: T) {
        heap.append(element)
        swim(heap.count - 1)
    }
    
    /// Add a new element onto a Priority Queue, limiting the size of the queue. O(n^2)
    /// If the size limit has been reached, the lowest priority element will be removed and returned.
    /// Note that because this is a binary heap, there is no easy way to find the lowest priority
    /// item, so this method can be inefficient.
    /// Also note, that only one item will be removed, even if count > maxCount by more than one.
    ///
    /// - parameter element: The element to be inserted into the Priority Queue.
    /// - parameter maxCount: The Priority Queue will not grow further if its count >= maxCount.
    /// - returns: the discarded lowest priority element, or `nil` if count < maxCount
    public mutating func push(_ element: T, maxCount: Int) -> T? {
        precondition(maxCount > 0)
        if count < maxCount {
            push(element)
        } else { // heap.count >= maxCount
            // find the min priority element (ironically using max here)
            if let discard = heap.max(by: ordered) {
                if ordered(discard, element) { return element }
                push(element)
                remove(discard)
                return discard
            }
        }
        return nil
    }

    /// Remove and return the element with the highest priority (or lowest if ascending). O(lg n)
    ///
    /// - returns: The element with the highest priority in the Priority Queue, or nil if the PriorityQueue is empty.
    public mutating func pop() -> T? {
        
        if heap.isEmpty { return nil }
        let count = heap.count
        if count == 1 { return heap.removeFirst() }  // added for Swift 2 compatibility
        // so as not to call swap() with two instances of the same location
        fastPop(newCount: count - 1)
        
        return heap.removeLast()
    }
    
    
    /// Removes the first occurence of a particular item. Finds it by value comparison using ==. O(n)
    /// Silently exits if no occurrence found.
    ///
    /// - parameter item: The item to remove the first occurrence of.
    public mutating func remove(_ item: T) {
        if let index = heap.firstIndex(of: item) {
            heap.swapAt(index, heap.count - 1)
            heap.removeLast()
            if index < heap.count { // if we removed the last item, nothing to swim
                swim(index)
                sink(index)
            }
        }
    }
    
    /// Removes all occurences of a particular item. Finds it by value comparison using ==. O(n^2)
    /// Silently exits if no occurrence found.
    ///
    /// - parameter item: The item to remove.
    public mutating func removeAll(_ item: T) {
        var lastCount = heap.count
        remove(item)
        while (heap.count < lastCount) {
            lastCount = heap.count
            remove(item)
        }
    }
    
    /// Get a look at the current highest priority item, without removing it. O(1)
    ///
    /// - returns: The element with the highest priority in the PriorityQueue, or nil if the PriorityQueue is empty.
    public func peek() -> T? {
        return heap.first
    }
    
    /// Eliminate all of the elements from the Priority Queue, optionally replacing the order.
    public mutating func clear() {
        heap.removeAll(keepingCapacity: false)
    }
    
    // Based on example from Sedgewick p 316
    private mutating func sink(_ index: Int) {
        var index = index
        while 2 * index + 1 < heap.count {
            
            var j = 2 * index + 1
            
            if j < (heap.count - 1) && ordered(heap[j], heap[j + 1]) { j += 1 }
            if !ordered(heap[index], heap[j]) { break }
            
            heap.swapAt(index, j)
            index = j
        }
    }
    
    /// Helper function for pop.
    ///
    /// Swaps the first and last elements, then sinks the first element.
    ///
    /// After executing this function, calling `heap.removeLast()` returns the popped element.
    /// - Parameter newCount: The number of elements in heap after the `pop()` operation is complete.
    private mutating func fastPop(newCount: Int) {
        var index = 0
        heap.withUnsafeMutableBufferPointer { bufferPointer in
            let _heap = bufferPointer.baseAddress! // guaranteed non-nil because count > 0
            swap(&_heap[0], &_heap[newCount])
            while 2 * index + 1 < newCount {
                var j = 2 * index + 1
                if j < (newCount - 1) && ordered(_heap[j], _heap[j+1]) { j += 1 }
                if !ordered(_heap[index], _heap[j]) { return }
                swap(&_heap[index], &_heap[j])
                index = j
            }
        }
    }
    
    // Based on example from Sedgewick p 316
    private mutating func swim(_ index: Int) {
        var index = index
        while index > 0 && ordered(heap[(index - 1) / 2], heap[index]) {
            heap.swapAt((index - 1) / 2, index)
            index = (index - 1) / 2
        }
    }
}

// MARK: - GeneratorType
extension PriorityQueue: IteratorProtocol {
    
    public typealias Element = T
    mutating public func next() -> Element? { return pop() }
}

// MARK: - SequenceType
extension PriorityQueue: Sequence {
    
    public typealias Iterator = PriorityQueue
    public func makeIterator() -> Iterator { return self }
}

// MARK: - CollectionType
extension PriorityQueue: Collection {
    
    public typealias Index = Int
    
    public var startIndex: Int { return heap.startIndex }
    
    public var endIndex: Int { return heap.endIndex }
    
    /// Return the element at specified position in the heap (not the order). O(1)
    ///
    /// - Parameter position:   the index of the element to retireve.
    ///                         **Must not be negative**
    ///                         and **must be less greater than **
    ///                         `endindex`.
    ///
    /// - Returns: the element at the specified position in the heap.
    public subscript(position: Int) -> T {
        precondition(
            startIndex..<endIndex ~= position,
            "SwiftPriorityQueue subscript: index out of bounds"
        )
        return heap[position]
    }
    
    public func index(after i: PriorityQueue.Index) -> PriorityQueue.Index {
        return heap.index(after: i)
    }
    
    
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension PriorityQueue: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String { return heap.description }
    public var debugDescription: String { return heap.debugDescription }
}



struct BigInt: Hashable, Comparable, CustomStringConvertible {
    let digits: [Int]

    init(_ num: Int) {
        if num == 0 {
            digits = [0]
            return
        }
        digits = String(num).compactMap { $0.wholeNumberValue! }
    }
    init(_ num: String) {
        guard num.map({ $0.isNumber }).allSatisfy({ $0 }) else {
            fatalError("Invalid number")
        }
        self.digits = num.compactMap { $0.wholeNumberValue! }
    }

    init(_ digits: [Int]) {
        // Filter leading zeros
        var startIdx = 0
        while startIdx < digits.count && digits[startIdx] == 0 {
            startIdx += 1
        }
        if startIdx == digits.count {
            self.digits = [0]
        } else {
            self.digits = Array(digits[startIdx..<digits.count])
        }
    }

    var description: String {
        return digits.map { String($0) }.joined()
    }

    var numDigits: Int {
        return digits.count
    }

    func split() -> (BigInt, BigInt) {
        let half = numDigits / 2
        var larray = [Int](), rarray = [Int]()
        larray.append(contentsOf: digits[0..<half])
        rarray.append(contentsOf: digits[half..<numDigits])
        let first = BigInt(larray)
        let second = BigInt(rarray)
        return (first, second)
    }

    func multPowTen(_ power: Int) -> BigInt {
        if power < 0 {
            return BigInt(digits.dropLast(abs(power)))
        } else if power > 0{
            return BigInt(digits + Array(repeating: 0, count: power))
        } else {
            return BigInt(digits)
        }
    }

    static func +(lhs: BigInt, rhs: BigInt) -> BigInt{
        let (longer, shorter) = lhs.digits.count > rhs.digits.count ? (lhs, rhs) : (rhs, lhs)
        let lenDiff = longer.digits.count - shorter.digits.count
        var result: [Int] = []

        for i in 0..<lenDiff {
            result.append(longer.digits[i])
        }
        for i in lenDiff..<longer.digits.count {
            let sum = longer.digits[i] + shorter.digits[i - lenDiff]
            result.append(sum)
        }

        // See if anything should be carried over
        var i = result.count - 1
        while i > 0 {
            if result[i] > 9 {
                let carry = result[i] / 10
                result[i] = result[i] % 10
                result[i-1] += carry
            }
            i -= 1
        }
        if result[0] > 9 {
            let carry = result[0] / 10
            result[0] = result[0] % 10
            result.insert(carry, at: 0)
        }

        return BigInt(result)
    }

    static func +(lhs: BigInt, rhs: Int) -> BigInt {
        return lhs + BigInt(rhs)
    }

    static func *(lhs: BigInt, rhs: Int) -> BigInt {
        let digits = lhs.digits
        var bigints: [BigInt] = []
        for i in 0..<digits.count {
            let powten = digits.count - i - 1
            let prod = digits[i] * rhs
            bigints.append(BigInt(prod).multPowTen(powten))
        }
        return bigints.reduce(BigInt(0), +)
    }

    static func >(lhs: BigInt, rhs: BigInt) -> Bool {
        if lhs.digits.count > rhs.digits.count { return true }
        if lhs.digits.count < rhs.digits.count { return false }
        for i in 0..<lhs.digits.count {
            if lhs.digits[i] > rhs.digits[i] { return true }
            if lhs.digits[i] < rhs.digits[i] { return false }
        }
        return false
    }

    static func ==(lhs: BigInt, rhs: BigInt) -> Bool {
        return lhs.digits == rhs.digits
    }

    static func ==(lhs: BigInt, rhs: Int) -> Bool {
        if rhs == 0 {
            return lhs.digits == [0]
        }
        return lhs == BigInt(rhs)
    }

    static func <(lhs: BigInt, rhs: BigInt) -> Bool {
        return !(lhs > rhs) && !(lhs == rhs)
    }

    static func >=(lhs: BigInt, rhs: BigInt) -> Bool {
        return lhs > rhs || lhs == rhs
    }

    static func <=(lhs: BigInt, rhs: BigInt) -> Bool {
        return lhs < rhs || lhs == rhs
    }
}



fileprivate func parseInput(useTestCase: Bool) -> [Int] {
    let rawInput: String
    if useTestCase {
        rawInput = "125 17"
    } else {
        rawInput = "4 4841539 66 5279 49207 134 609568 0"
    }

    return rawInput.components(separatedBy: .whitespaces).compactMap { Int($0) }
}

let LOG2024 = log10f(2024.0)
fileprivate func numDigits(_ num: Int) -> Int {
    var count = 1

    var num = num
    while num / 10 > 0 {
        count += 1
        num /= 10
    }
    return count
}

fileprivate func split(_ num: Int) -> (Int, Int) {
    let numDigits = numDigits(num)
    let half = numDigits / 2
    let first = num / Int(pow(10, Double(half)))
    let second = num % Int(pow(10, Double(half)))
    return (first, second)
}

fileprivate func splitLog(_ lognum: Float) -> (Float, Float) {
    let numDigits = Int(max(1, ceil(lognum)))
    let half = numDigits / 2
    let first = lognum - Float(half)
    let expsecond = Int(pow(10, lognum)) % Int(pow(10, Float(half)))
    return (first, log10(Float(expsecond)))
}


struct StoneLine {
    var stones: [Int]

    init(_ stones: [Int]) {
        self.stones = stones
    }

    mutating func blink(){
        var i = 0
        while i < stones.count {
            let curVal = stones[i]
            if curVal == 0 {
                self.stones[i] = 1
            } else if numDigits(curVal) % 2 == 0 {
                let (l,r) = split(curVal)
                stones[i] = l
                stones.insert(r, at: i+1)
                i += 1
            } else {
                stones[i] = curVal * 2024
            }
            i += 1
        }
    }
}


struct TimedStone: Comparable, Hashable {
    var val: Int
    var lifespan: Int

    init(_ stone: Int, _ lifespan: Int) {
        self.val = stone
        self.lifespan = lifespan
    }

    static func < (lhs: TimedStone, rhs: TimedStone) -> Bool {
        return lhs.lifespan < rhs.lifespan
    }

    static func == (lhs: TimedStone, rhs: TimedStone) -> Bool {
        return lhs.val == rhs.val && lhs.lifespan == rhs.lifespan
    }

    static func > (lhs: TimedStone, rhs: TimedStone) -> Bool {
        return lhs.lifespan > rhs.lifespan
    }

    static func >= (lhs: TimedStone, rhs: TimedStone) -> Bool {
        return lhs.lifespan >= rhs.lifespan
    }

    static func <= (lhs: TimedStone, rhs: TimedStone) -> Bool {
        return lhs.lifespan <= rhs.lifespan
    }
}

fileprivate struct FasterStoneLine{
    var stonequeue: PriorityQueue<TimedStone>

    init(_ stones: [Int], numBlinks blinks: Int) {
        // Stones: initial stone list
        // numBlinks: total number of blinks to simulate
        self.stonequeue = PriorityQueue(ascending: true, startingValues: stones.map { TimedStone($0, blinks) })
    }

    mutating func countFinalStones() -> Int{
        var count = 0

        while !stonequeue.isEmpty {
            var curStone = stonequeue.pop()!
            count += 1
            guard curStone.lifespan > 0 else {
                continue
            }

            for step in 0..<curStone.lifespan {
                if curStone.val == 0 {
                    curStone.val = 1
                } else if numDigits(curStone.val) % 2 == 0 {
                    let (l, r) = split(curStone.val)
                    curStone.val = l
                    stonequeue.push(TimedStone(r, curStone.lifespan - step - 1))
                } else {
                    curStone.val *= 2024
                }
            }
        }
        return count
    }
}


struct BigIntTimedStone: Comparable, Hashable {
    var val: BigInt
    var lifespan: Int

    init(_ stone: Int, _ lifespan: Int) {
        self.val = BigInt(stone)
        self.lifespan = lifespan
    }

    init(_ stone: BigInt, _ lifespan: Int) {
        self.val = stone
        self.lifespan = lifespan
    }

    static func < (lhs: BigIntTimedStone, rhs: BigIntTimedStone) -> Bool {
        return lhs.lifespan < rhs.lifespan
    }

    static func == (lhs: BigIntTimedStone, rhs: BigIntTimedStone) -> Bool {
        return lhs.val == rhs.val && lhs.lifespan == rhs.lifespan
    }

    static func > (lhs: BigIntTimedStone, rhs: BigIntTimedStone) -> Bool {
        return lhs.lifespan > rhs.lifespan
    }

    static func >= (lhs: BigIntTimedStone, rhs: BigIntTimedStone) -> Bool {
        return lhs.lifespan >= rhs.lifespan
    }

    static func <= (lhs: BigIntTimedStone, rhs: BigIntTimedStone) -> Bool {
        return lhs.lifespan <= rhs.lifespan
    }
}

fileprivate struct FastestStoneLine {
    let stones: [BigIntTimedStone]
    let initialLifespan: Int
    var scoreCache: [BigIntTimedStone: Int] = [:]

    init(_ stones: [Int], numBlinks blinks: Int) {
        self.stones = stones.map{ BigIntTimedStone($0, blinks)}
        self.initialLifespan = blinks
    }

    mutating func score(_ stone: BigIntTimedStone) -> Int {
        if let cached = scoreCache[stone] {
            return cached
        }
        if stone.lifespan == 0 {
            return 1
        }

        if stone.val == 0 {
            let newStone = BigIntTimedStone(1, stone.lifespan - 1)
            let newScore = score(newStone)
            if scoreCache[newStone] == nil {
                scoreCache[newStone] = newScore
            }
            return newScore
        } else if stone.val.numDigits % 2 == 0 {
            let (l, r) = stone.val.split()
            let lStone = BigIntTimedStone(l, stone.lifespan - 1)
            let rStone = BigIntTimedStone(r, stone.lifespan - 1)
            let lScore = score(lStone)
            let rScore = score(rStone)
            if scoreCache[lStone] == nil {
                scoreCache[lStone] = lScore
            }
            if scoreCache[rStone] == nil {
                scoreCache[rStone] = rScore
            }
            return lScore + rScore
        } else {
            let newStone = BigIntTimedStone(stone.val * 2024, stone.lifespan - 1)
            let newScore = score(newStone)
            if scoreCache[newStone] == nil {
                scoreCache[newStone] = newScore
            }
            return newScore
        }
    }

    mutating func scoreAllStones() -> Int {
        var total = 0
        for stone in stones {
            total += score(stone)
        }
        return total
    }
}

func dayEleven_partOne() {
    let input = parseInput(useTestCase: false)
    var line = StoneLine(input)
    let startTime = Date()
    for _ in 0..<25 {
        line.blink()
    }
    let endTime = Date()
    print("Total time: \(endTime.timeIntervalSince(startTime))")
    print(line.stones.count)
}


func dayEleven_partTwo() {
    let input = parseInput(useTestCase: false)
    let startTime = Date()
    var line = FastestStoneLine(input, numBlinks: 75)
    let count = line.scoreAllStones()
    let endTime = Date()
    print(count)
    print("Took \(endTime.timeIntervalSince(startTime)) seconds")
}



// print("Day 11, part 1")
// dayEleven_partOne() 

// print("Day 11, part 2")
// dayEleven_partTwo()

