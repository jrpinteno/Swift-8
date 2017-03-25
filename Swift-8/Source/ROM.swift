//
//  ROM.swift
//  Swift-8
//
//  Created by Xavier R. Pinteño on 24/03/2017.
//  Copyright © 2017 Xavier R. Pinteño. All rights reserved.
//

import Foundation

// TODO: Error handling
struct ROM {
	internal let bytes: [UInt8]

	init?(path: String) {
		guard let file = fopen(path, "rb") else {
			print("Couldn't open: \(path)")
			return nil
		}

		// Close file at the end of scope
		defer {
			fclose(file)
		}

		print("Opened: \(path)")
		// Check filesize in order to know how buffer size
		fseek(file, 0, SEEK_END)
		let filesize: Int = ftell(file)
		rewind(file)
		print("Size: \(filesize)")
		var buffer: [UInt8] = Array(repeating: 0, count: filesize)
		fread(&buffer, MemoryLayout<UInt8>.size, filesize, file)

		bytes = buffer
	}

	func dissassemble() {
		// Opcodes are 2 bytes long in Big Endian, and are organized using the first nibble (4 most signifcant bits) 
		for i in 0 ... bytes.count / 2 - 1 {
			let opcode: Opcode = Opcode(highByte: bytes[2 * i], lowByte: bytes[2 * i + 1])

			// TODO: Use switch with nib1
			if opcode.byteH >> 4 == 0x1 {
				print(String(format: "\(opcode) -> Jump to $%1X%02X", opcode.nib2, opcode.byteL))
			} else {
				print(String(format: "\(opcode) -> Not implemented yet."))
			}
		}
	}
}
