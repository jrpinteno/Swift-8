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
		print("Dissassemble")
		// Opcodes are 2 bytes long in Big Endian, and are organized using the first nibble (4 most signifcant bits) 
		for i in 0 ... bytes.count / 2 - 1 {
			let opcode: Opcode = Opcode(highByte: bytes[2 * i], lowByte: bytes[2 * i + 1])

			switch opcode.nib1 {
				case 0x0:
					switch (opcode.nib2, opcode.nib3, opcode.nib4) {
						case (0x0, _, 0x0): // 00E0
							print("\(opcode) -> Clear the screen.")

						case (0x0, _, 0xE): // 00EE
							print("\(opcode) -> Return from subroutine.")

						default: // 0NNN
							print("\(opcode) -> Calls RCA 1802 program.")
					}

				case 0x1: // 1NNN
					print(String(format: "\(opcode) -> Jump to address @%1X%02X", opcode.nib2, opcode.byteL))

				case 0x2: // 2NNN
					print(String(format: "\(opcode) -> Call subroutine at @%1X%02X", opcode.nib2, opcode.byteL))

				case 0x3: // 3XNN
					print(String(format: "\(opcode) -> Skip next instruction if V_%1X == %02X", opcode.nib2, opcode.byteL))

				case 0x4: // 4XNN
					print(String(format: "\(opcode) -> Skip next instruction if V_%1X != %02X", opcode.nib2, opcode.byteL))

				case 0x5: // 5XY0
					print(String(format: "\(opcode) -> Skip next instruction if V_%1X == V_%1X", opcode.nib2, opcode.nib3))

				case 0x6: // 6XNN
					print(String(format: "\(opcode) -> Sets \(opcode.byteL) to register V_%1X", opcode.nib2))

				case 0x7: // 7XNN
					print(String(format: "\(opcode) -> Adds \(opcode.byteL) to register V_%1X", opcode.nib2))

				case 0x8:
					switch opcode.nib4 {
						case 0x0: // 8XY0
							print(String(format: "\(opcode) -> V_%1X = V_%1X", opcode.nib2, opcode.nib3))

						case 0x1: // 8XY1
							print(String(format: "\(opcode) -> V_%1X |= V_%1X, side-effect V_F reset to zero", opcode.nib2, opcode.nib3))

						case 0x2: // 8XY2
							print(String(format: "\(opcode) -> V_%1X &= V_%1X, side-effect V_F reset to zero", opcode.nib2, opcode.nib3))

						case 0x3: // 8XY3
							print(String(format: "\(opcode) -> V_%1X ^= V_%1X, side-effect V_F reset to zero", opcode.nib2, opcode.nib3))

						case 0x4: // 8XY4
							print(String(format: "\(opcode) -> V_%1X += V_%1X, side-effect V_F set to 1 when there's carry, 0 otherwise", opcode.nib2, opcode.nib3))

						case 0x5: // 8XY5
							print(String(format: "\(opcode) -> V_%1X -= V_%1X, side-effect V_F set to 0 when there's borrow, 1 otherwise", opcode.nib2, opcode.nib3))

						case 0x6: // 8XY6
							print(String(format: "\(opcode) -> V_%1X >> 1, side-effect V_F set to least significant before shift ", opcode.nib2, opcode.nib3))

						case 0x7: // 8XY7
							print(String(format: "\(opcode) -> V_%1X = V_%1X - V_%1X, side-effect V_F set to 0 when there's borrow, 1 otherwise", opcode.nib2, opcode.nib3, opcode.nib2))

						case 0xE: // 8XYE
							print(String(format: "\(opcode) -> V_%1X << 1, side-effect V_F set to most significant before shift ", opcode.nib2, opcode.nib3))

						default:
							print("\(opcode) -> Not handled yet")
					}

				case 0x9: // 9XY0
					print(String(format: "\(opcode) -> Skip next instruction if V_%1X != V_%1X", opcode.nib2, opcode.nib3))

				case 0xA: // ANNN
					print(String(format: "\(opcode) -> Set register I to address @%1X%2X", opcode.nib2, opcode.byteL))

				case 0xB: // BNNN
					print(String(format: "\(opcode) -> Jump to V_0 + @%1X%2X", opcode.nib2, opcode.byteL))

				case 0xC: // CXNN
					print(String(format: "\(opcode) -> Sets V_%1X = byte(rand()) & %2X", opcode.nib2, opcode.byteL))

				case 0xD: // DXYN
					print(String(format: "\(opcode) -> Draw sprite (x:V_%1X, y:V_%1X, height: \(opcode.nib4)), side-effect V_F set to 1 if any pixel set->unset, 0 otherwise", opcode.nib2, opcode.nib3))

				case 0xE:
					switch opcode.nib4 {
						case 0xE: // EX9E
							print(String(format: "\(opcode) -> Skip next instruction if V_%1X == keypressed", opcode.nib2))

						case 0x1:
							print(String(format: "\(opcode) -> Skip next instruction if V_%1X != keypressed", opcode.nib2))

						default:
							print("\(opcode) -> Not handled yet")
					}

				case 0xF:
					switch (opcode.nib3, opcode.nib4) {
						case (0x0, 0x7):
							print(String(format: "\(opcode) -> V_%1X = get_delay()", opcode.nib2))

						case (0x0, 0xA):
							print(String(format: "\(opcode) -> V_%1X = get_key(), blocking operation", opcode.nib2))

						case (0x1, 0x5):
							print(String(format: "\(opcode) -> set_delay_timer(V_%1X)", opcode.nib2))

						case (0x1, 0x8):
							print(String(format: "\(opcode) -> set_sound_timer(V_%1X)", opcode.nib2))

						case (0x1, 0xE):
							print(String(format: "\(opcode) -> I += V_%1X", opcode.nib2))

						case (0x2, 0x9):
							print(String(format: "\(opcode) -> I = sprite_addr[V_%1X]", opcode.nib2))

						case (0x3, 0x3):
							print(String(format: "\(opcode) -> Stores the binary-coded decimal representation of V_%1X. @I hundreds, @(I+1) tens, @(I+2) units", opcode.nib2))

						case (0x5, 0x5):
							print(String(format: "\(opcode) -> reg_dump(V_%1X, &I). Store registers (V_0 - V_%1X) in memory beginning at address I", opcode.nib2, opcode.nib2))

						case (0x6, 0x5):
							print(String(format: "\(opcode) -> reg_load(V_%1X, &I). Loads to registers (V_0 - V_%1X) from memory beginning at address I", opcode.nib2, opcode.nib2))

						default:
							print("\(opcode) -> Not handled yet")
				}

				default:
						print(String(format: "\(opcode) -> Not decoded yet."))
			}
		}
	}
}
