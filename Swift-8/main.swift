//
//  main.swift
//  Swift-8
//
//  Created by Xavier R. Pinteño on 24/03/2017.
//  Copyright © 2017 Xavier R. Pinteño. All rights reserved.
//

import Foundation
import Cocoa

let cpuQueue: DispatchQueue = DispatchQueue(label: "chip8")
let cpuTimer: DispatchSourceTimer = DispatchSource.makeTimerSource()

let rom = ROM(path: "PONG")
rom?.disassemble()
var chip8: Machine = Machine()

chip8.loadRom(rom!)

// 1000Hz timer
cpuTimer.scheduleRepeating(deadline: .now(), interval: .milliseconds(1))
cpuTimer.setEventHandler {
	chip8.emulateCycle()
}

cpuTimer.resume()

// Temporarily for when using console so that it doesn't go away
dispatchMain()
