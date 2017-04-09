//
//  Opcode.swift
//  Swift-8
//
//  Created by Xavier R. Pinteño on 25/03/2017.
//  Copyright © 2017 Xavier R. Pinteño. All rights reserved.
//

import Foundation

/**
 * Chip8 has 35 different opcodes encoded in 2 bytes
 *
 * 8 bit byteH [nib1 | nib2] nib1 tells opcode kind
 * 8 bit byteL [nib3 | nib4] nibs[2-4] contain register, immediates or address when the three are combined
 */
struct Opcode : CustomStringConvertible {
	let byteH: UInt8
	let byteL: UInt8

	var nib1: UInt8 {
		get {
			return byteH >> 4
		}
	}

	var nib2: UInt8 {
		get {
			return byteH & 0x0F
		}
	}

	var nib3: UInt8 {
		get {
			return byteL >> 4
		}
	}

	var nib4: UInt8 {
		get {
			return byteL & 0x0F
		}
	}

	var description: String {
		return String(format: "%02X%02X: \(textDescription)", byteH, byteL)
	}

	private var textDescription: String {
		switch (nib1, nib2, nib3, nib4) {
			case (0x0, 0x0, 0xE, 0x0): // 00E0
				return "Clear screen"

			case (0x0, 0x0, 0xE, 0xE): // 00EE
				return "Return from subroutine"

			case (0x1, _, _, _): // 1NNN
				return String(format: "Jump to address @%1X%02X", nib2, byteL)

			case (0x2, _, _, _): // 2NNN
				return String(format: "Call subroutine at @%1X%02X", nib2, byteL)

			case (0x3, _, _, _): // 3XNN
				return String(format: "Skip next instruction if V_%1X == %02X", nib2, byteL)

			case (0x4, _, _, _): // 4XNN
				return String(format: "Skip next instruction if V_%1X != %02X", nib2, byteL)

			case (0x5, _, _, _): // 5XY0
				return String(format: "Skip next instruction if V_%1X == V_%1X", nib2, nib3)

			case (0x6, _, _, _): // 6XNN
				return String(format: "Sets \(byteL) to register V_%1X", nib2)

			case (0x7, _, _, _): // 7XNN
				return String(format: "Adds \(byteL) to register V_%1X", nib2)

			case (0x8, _, _, 0x0): // 8XY0
				return String(format: "V_%1X = V_%1X", nib2, nib3)

			case (0x8, _, _, 0x1): // 8XY1
				return String(format: "V_%1X |= V_%1X, side-effect V_F reset to zero", nib2, nib3)

			case (0x8, _, _, 0x2): // 8XY2
				return String(format: "V_%1X &= V_%1X, side-effect V_F reset to zero", nib2, nib3)

			case (0x8, _, _, 0x3): // 8XY3
				return String(format: "V_%1X ^= V_%1X, side-effect V_F reset to zero", nib2, nib3)

			case (0x8, _, _, 0x4): // 8XY4
				return String(format: "V_%1X += V_%1X, side-effect V_F set to 1 when there's carry, 0 otherwise", nib2, nib3)

			case (0x8, _, _, 0x5): // 8XY5
				return String(format: "V_%1X -= V_%1X, side-effect V_F set to 0 when there's borrow, 1 otherwise", nib2, nib3)

			case (0x8, _, _, 0x6): // 8XY6
				return String(format: "V_%1X >> 1, side-effect V_F set to least significant before shift", nib2, nib3)

			case (0x8, _, _, 0x7): // 8XY7
				return String(format: "V_%1X = V_%1X - V_%1X, side-effect V_F set to 0 when there's borrow, 1 otherwise", nib2, nib3, nib2)

			case (0x8, _, _, 0xE): // 8XYE
				return String(format: "V_%1X << 1, side-effect V_F set to most significant before shift", nib2, nib3)

			case (0x9, _, _, _): // 9XY0
				return String(format: "Skip next instruction if V_%1X != V_%1X", nib2, nib3)

			case (0xA, _, _, _): // ANNN
				return String(format: "Set register I to address @%1X%2X", nib2, byteL)

			case (0xB, _, _, _): // BNNN
				return String(format: "Jump to V_0 + @%1X%2X", nib2, byteL)

			case (0xC, _, _, _): // CXNN
				return String(format: "Sets V_%1X = byte(rand()) & %2X", nib2, byteL)

			case (0xD, _, _, _): // DXYN
				return String(format: "Draw sprite (x:V_%1X, y:V_%1X, height: \(nib4)), side-effect V_F set to 1 if any pixel set->unset, 0 otherwise", nib2, nib3)

			case (0xE, _, 0x9, 0xE): // EX9E
				return String(format: "Skip next instruction if V_%1X == keypressed", nib2)

			case (0xE, _, 0xA, 0x1): // EXA1
				return String(format: "Skip next instruction if V_%1X != keypressed", nib2)

			case (0xF, _, 0x0, 0x7):
				return String(format: "V_%1X = get_delay()", nib2)

			case (0xF, _, 0x0, 0xA):
				return String(format: "V_%1X = get_key(), blocking operation", nib2)

			case (0xF, _, 0x1, 0x5):
				return String(format: "set_delay_timer(V_%1X)", nib2)

			case (0xF, _, 0x1, 0x8):
				return String(format: "set_sound_timer(V_%1X)", nib2)

			case (0xF, _, 0x1, 0xE): // FX1E
				return String(format: "I += V_%1X", nib2)

			case (0xF, _, 0x2, 0x9): // FX29
				return String(format: "I = sprite_addr[V_%1X]", nib2)

			case (0xF, _, 0x3, 0x3): // FX33
				return String(format: "Stores the binary-coded decimal representation of V_%1X. @I hundreds, @(I+1) tens, @(I+2) units", nib2)

			case (0xF, _, 0x5, 0x5): // FX55
				return String(format: "reg_dump(V_%1X, &I). Store registers (V_0 - V_%1X) in memory beginning at address I", nib2, nib2)

			case (0xF, _, 0x6, 0x5): // FX65
				return String(format: "reg_load(V_%1X, &I). Loads to registers (V_0 - V_%1X) from memory beginning at address I", nib2, nib2)

			default:
				return "Not decoded yet"
		}
	}

	init(highByte: UInt8, lowByte: UInt8) {
		byteH = highByte
		byteL = lowByte
	}
}
