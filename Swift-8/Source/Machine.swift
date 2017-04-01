//
//  Machine.swift
//  Swift-8
//
//  Created by Xavier R. Pinteño on 26/03/2017.
//  Copyright © 2017 Xavier R. Pinteño. All rights reserved.
//

import Foundation

struct Machine: CustomStringConvertible {
	/**
	 * Chip 8 has a 4k memory usually distributed as follows
	 * [0x000 - 0x1FF] Font data
    * [0x200 - 0xEFF] 
    */
	var memory: [UInt8]

	// A total of 16 registers. 15 of them are general purpose V_0 - V_E and V_F
	var vRegisters: [UInt8]

	// Memory address register I, goes from 0x000 to 0xFFF
	var index: UInt16

	// Program counter, goes from 0x000 to 0xFFF
	var pc: UInt16

	// Stack pointer
	var sp: UInt16

	var stack: [UInt16]

	var description: String {
		return String(format: "pc: \(pc), registers: \(vRegisters)")
	}

	let fontSet: [UInt8] = [
		0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
		0x20, 0x60, 0x20, 0x20, 0x70, // 1
		0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
		0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
		0x90, 0x90, 0xF0, 0x10, 0x10, // 4
		0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
		0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
		0xF0, 0x10, 0x20, 0x40, 0x40, // 7
		0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
		0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
		0xF0, 0x90, 0xF0, 0x90, 0x90, // A
		0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
		0xF0, 0x80, 0x80, 0x80, 0xF0, // C
		0xE0, 0x90, 0x90, 0x90, 0xE0, // D
		0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
		0xF0, 0x80, 0xF0, 0x80, 0x80  // F
	]

	init() {
		memory = Array(repeating: 0, count: 4096)
		memory.replaceSubrange(0 ... fontSet.count - 1, with: fontSet)

		vRegisters = Array(repeating: 0, count: 16)
		stack = Array(repeating: 0, count: 16)
		index = 0
		pc = 0x200 // Program begins at this address
		sp = 0
	}

	mutating func loadRom(_ rom: ROM) {
		memory.replaceSubrange(Int(pc) ... (Int(pc) + rom.bytes.count - 1), with: rom.bytes)
	}

	mutating func emulateCycle() -> Bool {
		var isDecoded: Bool = true
		var isJump: Bool = false

		// Fetch opcode
		let opcode: Opcode = Opcode(highByte: memory[Int(pc)], lowByte: memory[Int(pc + 1)])

		// Decode and execute opcode
		switch (opcode.nib1, opcode.nib2, opcode.nib3, opcode.nib4) {
			case (0x1, _, _, _): // 1NNN
				pc = UInt16(opcode.nib2) << 8 | UInt16(opcode.byteL)
				isJump = true

			case (0x3, _, _, _): // 3XNN
				// Instruction skippers just increment pc by 2 twice, skipping the next immediate instruction
				if vRegisters[Int(opcode.nib2)] == opcode.byteL {
					pc += 2
				}

			case (0x4, _, _, _): // 4XNN
				// Instruction skippers just increment pc by 2 twice, skipping the next immediate instruction
				if vRegisters[Int(opcode.nib2)] != opcode.byteL {
					pc += 2
				}

			case (0x5, _, _, _): // 5XY0
				// Instruction skippers just increment pc by 2 twice, skipping the next immediate instruction
				if vRegisters[Int(opcode.nib2)] == vRegisters[Int(opcode.nib3)] {
					pc += 2
				}

			case (0x6, _, _, _): // 6XNN
				vRegisters[Int(opcode.nib2)] = opcode.byteL

			case (0x7, _, _, _): // 7XNN
				let x: Int = Int(opcode.nib2)
				vRegisters[x] += opcode.byteL

			case (0x8, _, _, 0x4): // 8XY4
				let x: Int = Int(opcode.nib2)
				let y: Int = Int(opcode.nib3)

				vRegisters[0xF] = (vRegisters[x] + vRegisters[y] > UInt8.max) ? 0x1 : 0x0
				vRegisters[x] += vRegisters[y]

			case (0x8, _, _, 0x5): // 8XY5
				let x: Int = Int(opcode.nib2)
				let y: Int = Int(opcode.nib3)

				vRegisters[0xF] = (vRegisters[x] - vRegisters[y] < 0) ? 0x0 : 0x1
				vRegisters[x] -= vRegisters[y]

			case (0x8, _, _, 0x6): // 8XY6
				let x: Int = Int(opcode.nib2)
				vRegisters[0xF] = vRegisters[x] & 0x1
				vRegisters[x] = vRegisters[x] >> 1

			case (0x8, _, _, 0x7): // 8XY7
				let x: Int = Int(opcode.nib2)
				let y: Int = Int(opcode.nib3)

				vRegisters[0xF] = (vRegisters[y] - vRegisters[x] < 0) ? 0x0 : 0x1
				vRegisters[x] = vRegisters[y] - vRegisters[x]

			case (0x8, _, _, 0xE): // 8XYE
				let x: Int = Int(opcode.nib2)
				vRegisters[0xF] = (vRegisters[x] >> 7) & 0x1
				vRegisters[x] = vRegisters[x] << 1

			case (0xB, _, _, _): // BNNN
				pc = UInt16(vRegisters[0x0]) + (UInt16(opcode.nib2) << 8 | UInt16(opcode.byteL))
				isJump = true


			case (0x9, _, _, _): // 9XY0
				// Instruction skippers just increment pc by 2 twice, skipping the next immediate instruction
				if vRegisters[Int(opcode.nib2)] != vRegisters[Int(opcode.nib3)] {
					pc += 2
				}

			case (0xA, _, _, _): // ANNN
				index = UInt16(opcode.nib2) << 8 | UInt16(opcode.byteL)

			case (0xF, _, 0x1, 0xE): // FX1E
				index += UInt16(vRegisters[Int(opcode.nib2)])

			case (0xF, _, 0x3, 0x3): // FX33
				var value: UInt8 = vRegisters[Int(opcode.nib2)]
				memory[Int(index + 2)] = value % 10
				value = value / 10
				memory[Int(index + 1)] = value % 10
				value = value / 10
				memory[Int(index)] = value % 10

			case (0xF, _, 0x5, 0x5): // FX55
				let x: Int = Int(opcode.nib2)

				memory.replaceSubrange(Int(index) ... Int(index) + x, with: vRegisters[0 ... x])

			case (0xF, _, 0x6, 0x5): // FX65
				let x: Int = Int(opcode.nib2)

				vRegisters.replaceSubrange(0 ... x, with: memory[Int(index) ... Int(index) + x])

			default:
				print("\(opcode) -> Not decoded yet")
				isDecoded = false
		}

		// Increase program counter unless there is a jump instruction
		if !isJump {
			pc += 2
		}

		return isDecoded
	}
}
