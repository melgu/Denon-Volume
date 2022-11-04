//
//  Model.swift
//  Denon Volume
//
//  Created by Melvin Gundlach on 04.11.22.
//

import SwiftUI

@MainActor
class Model: ObservableObject {
	@Published var isOn = false
	@Published var address = ""
	@Published var volume: Double = 40
	
	func showInformation() {
		print("Show Information")
	}
	
	func commitAddress() {
		print("Commit Address")
	}
	
	func quit() {
		print("Quit")
		NSApplication.shared.terminate(self)
	}
}
