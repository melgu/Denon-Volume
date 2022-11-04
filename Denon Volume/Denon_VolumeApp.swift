//
//  Denon_VolumeApp.swift
//  Denon Volume
//
//  Created by Melvin Gundlach on 04.11.22.
//

import SwiftUI

@main
struct Denon_VolumeApp: App {
	@StateObject private var model = Model()
	
	var body: some Scene {
		MenuBarExtra {
			ContentView(model: model)
		} label: {
			icon
		}
		.menuBarExtraStyle(.window)
	}
	
	@ViewBuilder
	private var icon: some View {
		if model.isOn {
			switch model.volume {
			case 0..<30: Image(systemName: "dial.low")
			case 30..<50: Image(systemName: "dial.medium")
			default: Image(systemName: "dial.high").foregroundColor(.red) // FIXME: Colors don't work
			}
		} else {
			Image(systemName: "dial.low").foregroundColor(.secondary) // FIXME: Colors don't work
		}
	}
}
