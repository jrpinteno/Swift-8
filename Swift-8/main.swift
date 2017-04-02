//
//  main.swift
//  Swift-8
//
//  Created by Xavier R. Pinteño on 24/03/2017.
//  Copyright © 2017 Xavier R. Pinteño. All rights reserved.
//

import Foundation

let rom = ROM(path: "pong.ch8")
rom?.dissassemble()
var chip8: Machine = Machine()

chip8.loadRom(rom!)

var decoded: Bool
repeat {
	print(chip8)
	decoded = chip8.emulateCycle()
} while decoded == true

chip8.printChipState()
