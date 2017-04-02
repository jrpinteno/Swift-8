//
//  Screen.swift
//  Swift-8
//
//  Created by Xavier R. Pinteño on 02/04/2017.
//  Copyright © 2017 Xavier R. Pinteño. All rights reserved.
//

import Foundation

struct Screen {
	let screenWidth: Int
	let screenHeight: Int

	private var screen: [UInt8]

	init(width: Int, height: Int) {
		screenWidth = width
		screenHeight = height

		screen = Array(repeating: 0, count: width * height)
	}

	mutating func clear() {
		screen = Array(repeating: 0, count: screenWidth * screenHeight)
	}

	func pixel(at x: Int, y: Int) -> UInt8 {

		let pixelIndex = x * screenHeight + y
		return screen[pixelIndex]
	}

	mutating func set(pixel: UInt8, x: Int, y: Int) {
		let pixelIndex = x * screenHeight + y
		screen[pixelIndex] = pixel
	}

	mutating func draw(_ sprite: [UInt8], x: Int, y: Int) -> Bool {
		var didErasePixel: Bool = false

		for (j, rowSprite) in zip(0 ..< sprite.count, sprite) {
			for i in 0 ..< 8 {
				let screenX = (x + i) % screenWidth
				let screenY = (y + j) % screenHeight

				let currentPixel: UInt8 = pixel(at: screenX, y: screenY)
				let spritePixel: UInt8 = (rowSprite >> UInt8(7 - i)) & 0x1 == 0x1 ? 0xFF : 0

				let newPixel: UInt8 = currentPixel ^ spritePixel
				set(pixel: newPixel, x: screenX, y: screenY)

				if currentPixel != 0 && newPixel == 0 {
					didErasePixel = true
				}
			}
		}

		return didErasePixel
	}

	func printScreen() {
		print("Next screen")
		for j in 0 ..< screenHeight {
			var row: String = ""

			for i in 0 ..< screenWidth {
				row.append(pixel(at: i, y: j) == 0 ? "0" : "1")
			}

			print(row)
		}
	}
}
