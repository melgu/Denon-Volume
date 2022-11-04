//
//  ContentView.swift
//  Denon Volume
//
//  Created by Melvin Gundlach on 04.11.22.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var model: Model
	
	var body: some View {
		VStack {
			ZStack {
				HStack {
					Button {
						model.showInformation()
					} label: {
						Image(systemName: "info")
					}
					.accessibilityLabel("Information")
					.help("Information")
					
					Spacer()
					
					Toggle(isOn: $model.isOn) {
						EmptyView()
					}
					.accessibilityLabel("Is on")
					.help("Is on")
				}
				
				Text("Network Name")
			}
			
			TextField("Address", text: $model.address) {
				model.commitAddress()
			}
			
			Slider(value: $model.volume, in: 0...70, step: 1) {
				EmptyView()
			}
			.accessibilityLabel("Volume")
			.accessibilityValue("\(Int(model.volume))")
			.disabled(!model.isOn)

			ZStack {
				HStack {
					Text("\(Int(model.volume))")
						.foregroundColor(model.isOn ? .primary : .secondary)
					
					Spacer()
					
					Button {
						model.quit()
					} label: {
						Image(systemName: "xmark")
					}
					.accessibilityLabel("Quit")
					.help("Quit")
				}
				
				Text("Volume")
					.foregroundColor(model.isOn ? .primary : .secondary)
			}
		}
		.padding()
		.frame(width: 200)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(model: Model())
	}
}
