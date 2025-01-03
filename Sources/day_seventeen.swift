import Foundation

fileprivate struct Instruction {
    let opcode: Int
    let operand: Int
}

fileprivate struct Computer {
    var registers: (A: Int, B: Int, C: Int)
    var instructionPointer: Int
    var instructions: [Instruction]

    init(registers: (A: Int, B: Int, C: Int), instructions: [Instruction]) {
        self.registers = registers
        self.instructionPointer = 0
        self.instructions = instructions
    }

    func evalComboOperand(_ operand: Int) -> Int {
        switch operand {
            case 0...3:
            return operand
            case 4:
            return registers.A
            case 5:
            return registers.B
            case 6:
            return registers.C
            default:
            fatalError("Invalid Program")
        }
    }

    mutating func execute(_ instruction: Instruction) -> Int?{
        let code = instruction.opcode
        let operand = instruction.operand
        var output: Int? = nil
        switch code {
            case 0:  // Bit shift register A right by combo operand
            let update = registers.A >> evalComboOperand(operand)
            registers.A = update
            case 1: // Bitwise XOR b and literal operand
            let update = registers.B ^ operand
            registers.B = update
            case 2: // Write combo operand mod 8 to B
            let update = evalComboOperand(operand) % 8
            registers.B = update
            case 3: // If A nonzero, jump to literal operand
            // Dividing by two here because I use indices into an array of `Instruction`,
            // whereas the problem statement uses indices into the combined array of 
            // opcodes and operands
            instructionPointer = (registers.A != 0) ? operand / 2 : instructionPointer + 1
            return nil
            case 4: // B xor C -> B
            let update = registers.B ^ registers.C
            registers.B = update
            case 5: // output combo mod 8
            output = evalComboOperand(operand) % 8
            case 6: // A >> combo -> B
            let update = registers.A >> evalComboOperand(operand)
            registers.B = update
            case 7: // A >> combo -> C
            let update = registers.A >> evalComboOperand(operand)
            registers.C = update
            default:
            fatalError("Invalid program")
        }
        /** program:
        2,4  A mod 8 -> B
        1,7  B ^ 7   -> B  Inverts B
        7,5  A >> B  -> C
        0,3  A >> 3  -> A
        1,7  B ^ 7   -> B  Restores original B
        4,1  B ^ C   -> B  
        5,5  B % 8   -> OUT  Outputs B xor the
        3,0  repeat floor(1/3 log2(A_0)) times
        */
        // Outputs the Xor of the last three bits of A and bits k+2, k+1, and k where k is ~(a%8)
        // Takes last three bits of A, inverts them, and 

        // Desired output: 2,4,1,7,7,5,0,3,1,7,4,1,5,5,3,0
        // last output: 000 = B ^ A>>(~B) => B = A>>(~B) 
        // Minimized by making first 10 (shift 7 + op on 3) MSBs of A = 0
        // A: 000 000 000 0
        // Desired output 3: 011 = B ^ (A >> ~B)
        // B = 011
        // A: ...011
        // Desired output 5: 101 = B ^ (A >> ~B)
        // B = 101
        // A: ...011 101

        
        // See comment on case 5
        instructionPointer += 1
        return output
    }

    mutating func runProgram() -> String {
        var outputs: [Int] = []

        while (0..<instructions.count).contains(instructionPointer){
            if let output = execute(instructions[instructionPointer]) {
                outputs.append(output)
            }
        }

        return outputs.map{String($0)}.joined(separator: ",")
    }

    mutating func producesOutput(_ target: [Int]) -> Bool {
        var outputs: [Int] = []

        while (0..<instructions.count).contains(instructionPointer){
            if let output = execute(instructions[instructionPointer]) {
                outputs.append(output)
                guard outputs.count <= target.count else {return false}
                guard outputs.last! == target[outputs.count - 1] else {return false}
            }
        }
        
        return outputs == target
    }
}

fileprivate func buildInputForDesiredOutput(desiredOutput: [Int]) -> Int {
    let bits: UInt = 0
    var digits = desiredOutput
    digits.reverse()

    if let bits = bitsForDigits(digits, existingBits: bits) {
        return Int(bits)
    }
    fatalError("no solution found sadge")
}

fileprivate func bitsForDigits(_ digits: any Collection<Int>, existingBits bits: UInt) -> UInt? {
    guard !digits.isEmpty else { return bits }
    for B_c in 0..<8 {
        let B = UInt(B_c)
        let BInv = ~B & UInt(7)
        let AwithB = (bits << 3) + B
        let result = B ^ ((AwithB >> BInv) & UInt(7))
        if Int(result) == digits.first {
            let newBits = AwithB
            if let future = bitsForDigits(digits.dropFirst(), existingBits: newBits) {
                return future
            } else { continue }
        }
    }
    return nil
}

fileprivate func parseInput(useTestCase: Bool) -> Computer {
    let rawInput: String
    if useTestCase {
        rawInput = """
        Register A: 729
        Register B: 0
        Register C: 0

        Program: 0,3,5,4,3,0
        """
    } else {
        rawInput = """
        Register A: 64012472
        Register B: 0
        Register C: 0

        Program: 2,4,1,7,7,5,0,3,1,7,4,1,5,5,3,0
        """
    }

    let digits = Set("0123456789")
    let split = rawInput.components(separatedBy: .newlines)
    let registerA = Int(split[0].filter{ digits.contains($0)})!
    let registerB = Int(split[1].filter{ digits.contains($0)})!
    let registerC = Int(split[2].filter{ digits.contains($0)})!

    let program = split.last!.components(separatedBy: ",").map{Int($0.filter{digits.contains($0)})!}
    guard program.count % 2 == 0 else {fatalError("Program of odd size")}
    var instructions = [Instruction]()
    for i in stride(from: 0, to: program.count, by: 2) {
        instructions.append(Instruction(opcode: program[i], operand: program[i+1]))
    }

    return Computer(registers: (A: registerA, B: registerB, C: registerC), instructions: instructions)
}


func daySeventeen_partOne() {
    var comp = parseInput(useTestCase: true)
    print(comp.runProgram())
}

func daySeventeen_partTwo() {
    let initialState = parseInput(useTestCase: false)
    let desiredOutput = initialState.instructions.reduce([Int]()) { (acc, ins) in 
        acc + [ins.opcode, ins.operand]
    }

    print(desiredOutput.map{String($0)}.joined(separator: ""))
    let newA = buildInputForDesiredOutput(desiredOutput: desiredOutput)

    // double check that the new A produces the desired output
    var copyComp = initialState
    copyComp.registers.A = newA
    print("Desired: \(desiredOutput)")
    print("Found: \(copyComp.runProgram())")
    print("New A: \(newA)")
}
