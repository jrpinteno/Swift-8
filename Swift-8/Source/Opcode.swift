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
		return String(format: "%02X%02X", byteH, byteL)
	}

	init(highByte: UInt8, lowByte: UInt8) {
		byteH = highByte
		byteL = lowByte
	}
}
