//
//  KeyMap.swift
//  Swift-8
//
//  Created by Xavier R. Pinteño on 21/04/2017.
//  Copyright © 2017 Xavier R. Pinteño. All rights reserved.
//

import Foundation

func keymap(value: Int) -> Int? {

	guard let scalar = UnicodeScalar(value) else {
		return nil
	}

	let key = Character(scalar)

	switch key {
		case "1":
			return 0x1

		case "2":
			return 0x2

		case "3":
			return 0x3

		case "4":
			return 0x4

		case "5":
			return 0x5

		case "6":
			return 0x6

		case "7":
			return 0x7

		case "8":
			return 0x8

		case "9":
			return 0x9

		case "a":
			return 0xA

		case "b":
			return 0xB

		case "c":
			return 0xC

		case "d":
			return 0xD

		case "e":
			return 0xE

		case "f":
			return 0xF

		default:
			return nil
	}
}
