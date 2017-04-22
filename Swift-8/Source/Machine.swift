//
//  Machine.swift
//  Swift-8
//
//  Created by Xavier R. Pinteño on 26/03/2017.
//  Copyright © 2017 Xavier R. Pinteño. All rights reserved.
//

import Foundation

class Machine: CustomStringConvertible {
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

	var soundTimer: UInt8
	var delayTimer: UInt8

	private let screenWidth: Int = 64
	private let screenHeight: Int = 32

	var screen: Screen
	var lastOpcode: Opcode?
	var keypad: [Bool]

	var lastTimerTick: Date = Date.distantPast

	var chipStateHeader: [String] {
		return ["PC", "SP", "Opcode", "V0", "V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8", "V9", "VA", "VB", "VC", "VD", "VE", "VF"]
	}

	func computeWidths() -> [Int] {
		var columnWidths: [Int] = []

		for i in 0 ..< chipStateHeader.count {
			let columnLabel = chipStateHeader[i]
			columnWidths.append(columnLabel.characters.count)
		}

		for i in 0 ..< chipStateTable.count {
			for j in 0 ..< chipStateTable[i].count {
				let item = chipStateTable[i][j]
				if columnWidths[j] < item.characters.count {
					columnWidths[j] = item.characters.count
				}
			}
		}

		return columnWidths
	}

	var chipStateTable: [[String]] = [[]]

	func printChipState() {
		var firstRow: String = "|"
		var columnWidths: [Int] = computeWidths()

		for i in 0 ..< columnWidths.count {
			let columnLabel = chipStateHeader[i]
			let paddingNeeded: Int = columnWidths[i] - columnLabel.characters.count
			let padding: String = repeatElement(" ", count: paddingNeeded).joined(separator: "")
			let columnHeader: String = " \(padding)\(columnLabel) |"
			firstRow += columnHeader
		}

		print(firstRow)

		for i in 0 ..< chipStateTable.count {
			// Start the output string
			var out = "|"

			// Append each item in this row to the string
			for j in 0 ..< chipStateTable[i].count {
				let item = chipStateTable[i][j]
				let paddingNeeded: Int = abs(columnWidths[j] - item.characters.count)
				let padding: String = repeatElement(" ", count: paddingNeeded).joined(separator: "")
				out += " \(padding)\(item) |"
			}

			print(out)
		}
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

	var description: String {
		return String(format: "Opcode: \(String(describing: lastOpcode)) SP: \(sp) PC: 0x%04X, registers: \(vRegisters)", pc)
	}

	init() {
		memory = Array(repeating: 0, count: 4096)
		memory.replaceSubrange(0 ... fontSet.count - 1, with: fontSet)
		vRegisters = Array(repeating: 0, count: 16)
		stack = Array(repeating: 0, count: 16)

		screen = Screen(width: screenWidth, height: screenHeight)
		keypad = Array(repeating: false, count: 16)

		index = 0
		pc = 0x200 // Program begins at this address
		sp = 0
		delayTimer = 0
		soundTimer = 0

		listenKeys()
	}

	func loadRom(_ rom: ROM) {
		memory.replaceSubrange(Int(pc) ... (Int(pc) + rom.bytes.count - 1), with: rom.bytes)
	}

	func emulateCycle() {
		var updatePC: Bool = true

		// Fetch opcode
		let opcode: Opcode = Opcode(highByte: memory[Int(pc)], lowByte: memory[Int(pc + 1)])
		lastOpcode = opcode
		updateState(opcode: opcode)
		print(self)

		// Decode and execute opcode
		switch (opcode.nib1, opcode.nib2, opcode.nib3, opcode.nib4) {
			case (0x0, 0x0, 0xE, 0x0): // 00E0
				screen.clear()

			case (0x0, 0x0, 0xE, 0xE): // 00EE
				sp -= 1
				pc = stack[Int(sp)]

			case (0x1, _, _, _): // 1NNN
				pc = UInt16(opcode.nib2) << 8 | UInt16(opcode.byteL)
				updatePC = false

			case (0x2, _, _, _): // 2NNN
				stack[Int(sp)] = pc
				sp += 1
				pc = UInt16(opcode.nib2) << 8 | UInt16(opcode.byteL)
				updatePC = false

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
				vRegisters[x] = vRegisters[x] &+ opcode.byteL

			case (0x8, _, _, 0x0): // 8XY0
				vRegisters[Int(opcode.nib2)] = vRegisters[Int(opcode.nib3)]

			case (0x8, _, _, 0x1): // 8XY1
				vRegisters[Int(opcode.nib2)] |= vRegisters[Int(opcode.nib3)]
				vRegisters[0xF] = 0x0;

			case (0x8, _, _, 0x2): // 8XY2
				vRegisters[Int(opcode.nib2)] &= vRegisters[Int(opcode.nib3)]
				vRegisters[0xF] = 0x0;

			case (0x8, _, _, 0x3): // 8XY3
				vRegisters[Int(opcode.nib2)] ^= vRegisters[Int(opcode.nib3)]
				vRegisters[0xF] = 0x0;

			case (0x8, _, _, 0x4): // 8XY4
				let x: Int = Int(opcode.nib2)
				let y: Int = Int(opcode.nib3)

				var carry: Bool
				(vRegisters[x], carry) = UInt8.addWithOverflow(vRegisters[x], vRegisters[y])
				vRegisters[0xF] = carry ? 0x1 : 0x0

			case (0x8, _, _, 0x5): // 8XY5
				let x: Int = Int(opcode.nib2)
				let y: Int = Int(opcode.nib3)

				var borrow: Bool
				(vRegisters[x], borrow) = UInt8.subtractWithOverflow(vRegisters[x], vRegisters[y])
				vRegisters[0xF] = borrow ? 0x0 : 0x1

			case (0x8, _, _, 0x6): // 8XY6
				let x: Int = Int(opcode.nib2)
				vRegisters[0xF] = vRegisters[x] & 0x1
				vRegisters[x] = vRegisters[x] >> 1

			case (0x8, _, _, 0x7): // 8XY7
				let x: Int = Int(opcode.nib2)
				let y: Int = Int(opcode.nib3)

				var borrow: Bool
				(vRegisters[x], borrow) = UInt8.subtractWithOverflow(vRegisters[y], vRegisters[x])
				vRegisters[0xF] = borrow ? 0x0 : 0x1

			case (0x8, _, _, 0xE): // 8XYE
				let x: Int = Int(opcode.nib2)
				vRegisters[0xF] = (vRegisters[x] >> 7) & 0x1
				vRegisters[x] = vRegisters[x] << 1

			case (0x9, _, _, _): // 9XY0
				// Instruction skippers just increment pc by 2 twice, skipping the next immediate instruction
				if vRegisters[Int(opcode.nib2)] != vRegisters[Int(opcode.nib3)] {
					pc += 2
				}

			case (0xA, _, _, _): // ANNN
				index = UInt16(opcode.nib2) << 8 | UInt16(opcode.byteL)

			case (0xB, _, _, _): // BNNN
				pc = UInt16(vRegisters[0x0]) + (UInt16(opcode.nib2) << 8 | UInt16(opcode.byteL))
				updatePC = false

			case (0xC, _, _, _): // CXNN
				let random: UInt8 = UInt8(arc4random_uniform(UInt32(UInt8.max)))
				vRegisters[Int(opcode.nib2)] = random & opcode.byteL

			case (0xD, _, _, _): // DXYN
				drawSprite(x: Int(vRegisters[Int(opcode.nib2)]), y: Int(vRegisters[Int(opcode.nib3)]), height: Int(opcode.nib4))

			case (0xE, _, 0x9, 0xE): // EX9E
				if keypad[Int(vRegisters[Int(opcode.nib2)])] {
					pc += 2
				}

			case (0xE, _, 0xA, 0x1): // EXA1
				if !keypad[Int(vRegisters[Int(opcode.nib2)])] {
					pc += 2
				}

			case (0xF, _, 0x0, 0xA):
				print("Waiting for keypress")

			case (0xF, _, 0x0, 0x7):
				vRegisters[Int(opcode.nib2)] = delayTimer

			case (0xF, _, 0x1, 0x5):
				delayTimer = vRegisters[Int(opcode.nib2)]

			case (0xF, _, 0x1, 0x8):
				soundTimer = vRegisters[Int(opcode.nib2)]

			case (0xF, _, 0x1, 0xE): // FX1E
				index += UInt16(vRegisters[Int(opcode.nib2)])

			case (0xF, _, 0x2, 0x9): // FX29
				// Each font sprite uses 5 bytes and they are stored beginning of memory
				index = UInt16(vRegisters[Int(opcode.nib2)] * 5)

			case (0xF, _, 0x3, 0x3): // FX33
				print(String(format:"Register V_%1X: \(vRegisters[Int(opcode.nib2)])", opcode.nib2))
				var value: UInt8 = vRegisters[Int(opcode.nib2)]
				print(value)
				memory[Int(index + 2)] = value % 10
				print(value % 10)
				value = value / 10
				memory[Int(index + 1)] = value % 10
				print(value % 10)
				value = value / 10
				memory[Int(index)] = value % 10
				print(value % 10)

			case (0xF, _, 0x5, 0x5): // FX55
				let x: Int = Int(opcode.nib2)

				memory.replaceSubrange(Int(index) ... Int(index) + x, with: vRegisters[0 ... x])

			case (0xF, _, 0x6, 0x5): // FX65
				let x: Int = Int(opcode.nib2)

				vRegisters.replaceSubrange(0 ... x, with: memory[Int(index) ... Int(index) + x])

			default:
				print("\(opcode) -> Not decoded yet")
		}

		// Increase program counter unless there is a jump instruction
		if updatePC {
			pc += 2
		}

		let now = Date()
		if now.timeIntervalSince(lastTimerTick) > 1.0/60.0 {
			if delayTimer > 0 {
				delayTimer -= 1
			}

			if soundTimer > 0 {
				soundTimer -= 1
			}

			lastTimerTick = now
		}
	}

	private func updateState (opcode: Opcode) {
		var newState: [String] = []
		newState.append(String(format: "0x%04X", pc))
		newState.append(String(sp))
		newState.append(String(describing: opcode))
		newState.append(contentsOf: vRegisters[0 ..< vRegisters.count].map { String($0) })

		chipStateTable.append(newState)
	}

	private func drawSprite(x: Int, y: Int, height: Int) {
		vRegisters[0xF] = 0x0

		var sprite: [UInt8] = Array(repeating: 0, count: height)
		sprite.replaceSubrange(0 ..< height, with: memory[Int(index) ..< Int(index) + height])

		let didErasePixel: Bool = screen.draw(sprite, x: x, y: y)

		if didErasePixel {
			vRegisters[0xF] = 0x1
		}

		screen.printScreen()
	}

	func setKey(key: Int) {
		keypad[key] = !keypad[key]
	}

	func listenKeys() {
		DispatchQueue.global(qos: .background).async { [unowned self] in
			let test: Int = self.GetKeyPress()
			if let key = keymap(value: test) {
				self.setKey(key: key)
			}

			self.listenKeys()
		}
	}

	// This comes from StackOverflow, keyPress without entering
	// http://stackoverflow.com/questions/25551321/xcode-swift-command-line-tool-reads-1-char-from-keyboard-without-echo-or-need-to
	// Only for debug purposes
	func GetKeyPress () -> Int {
		var key: Int = 0
		let c: cc_t = 0
		let cct = (c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c) // Set of 20 Special Characters
		var oldt: termios = termios(c_iflag: 0, c_oflag: 0, c_cflag: 0, c_lflag: 0, c_cc: cct, c_ispeed: 0, c_ospeed: 0)

		tcgetattr(STDIN_FILENO, &oldt) // 1473
		var newt = oldt
		newt.c_lflag = 1217  // Reset ICANON and Echo off
		tcsetattr( STDIN_FILENO, TCSANOW, &newt)
		key = Int(getchar())  // works like "getch()"
		tcsetattr( STDIN_FILENO, TCSANOW, &oldt)
		return key
	}
}
