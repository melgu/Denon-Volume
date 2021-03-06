//
//  DenonCommunicator.swift
//  Denon Volume
//
//  Created by Melvin Gundlach.
//  Copyright © 2018 Melvin Gundlach. All rights reserved.
//

import Foundation

public class DenonCommunicator {
	
	// MARK: - Variables
	weak var appDelegate: AppDelegate?
	
	let volumeMinValue = 0
	let volumeMaxValue = 70
	let volumeStepsBig = 3
	let volumeStepsLittle = 1
	
	var deviceName = "Denon-AVR"
	var lastTimeSend = Date()
	var lastTimeReceive = Date()
	var lastState = false
	var lastVolume = 0
	
	let session: URLSession
	
	init() {
		let sessionConfig = URLSessionConfiguration.default
		sessionConfig.timeoutIntervalForRequest = 1.0 // URL Session Timout per partial Request
		sessionConfig.timeoutIntervalForResource = 1.0 // URL Session Total Timout per Resourcwe
		session = URLSession(configuration: sessionConfig)
	}
	
	
	// MARK: - Functions
	
	func enforceLastVolumeBoundaries() {
		if lastVolume < volumeMinValue {
			lastVolume = volumeMinValue
		} else if volumeMaxValue < lastVolume {
			lastVolume = volumeMaxValue
		}
	}
	
	func updateUI(volume: Int, state: Bool, reachable: Bool) {
		appDelegate?.updateUI(volume: volume, state: state, reachable: reachable)
	}
	
	func setDeviceName(name: String) {
		deviceName = name
	}
	
	func volumeUpBig() {
		let result = fetchVolume()
		
		if result.successful && result.timeInterval {
			lastVolume += volumeStepsBig
			enforceLastVolumeBoundaries()
			sendVolume(volume: lastVolume)
		}
	}
	
	func volumeDownBig() {
		let result = fetchVolume()
		
		if result.successful && result.timeInterval {
			lastVolume -= volumeStepsBig
			enforceLastVolumeBoundaries()
			sendVolume(volume: lastVolume)
		}
	}
	
	func volumeUpLittle() {
		let result = fetchVolume()
		
		if result.successful && result.timeInterval {
			lastVolume += volumeStepsLittle
			enforceLastVolumeBoundaries()
			sendVolume(volume: lastVolume)
		}
	}
	
	func volumeDownLittle() {
		let result = fetchVolume()
		
		if result.successful && result.timeInterval {
			lastVolume -= volumeStepsLittle
			enforceLastVolumeBoundaries()
			sendVolume(volume: lastVolume)
		}
	}
	
	
	// Volume 0-70, return otherwise (40 for testing)
	// successful: Connection to AVR successful
	// timeInterval: 'false' if too short after previous execution
	@discardableResult func sendVolume(volume: Int) -> (successful: Bool, timeInterval: Bool) {
		if Date().timeIntervalSince(lastTimeSend) < 0.05 {
			return (true, false)
		} else {
			lastTimeSend = Date()
		}
		
		let allowedCharacters = "^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,.-!/()=?`*;:_{}[]\\|~"
		deviceName = deviceName.filter { allowedCharacters.contains($0) }
		let url = URL(string: "http://\(deviceName)/goform/formiPhoneAppVolume.xml?1+-\(80-volume)")
		var successful = true
		
		let semaphore = DispatchSemaphore(value: 0)
		
		let task = session.dataTask(with: url!) { _, _, error in
			guard error == nil else {
				print(error!)
				successful = false
				semaphore.signal()
				return
			}
			
			self.lastVolume = volume
			semaphore.signal()
		}
		
		task.resume()
		semaphore.wait()
		
		print(lastVolume)
		self.updateUI(volume: volume, state: lastState, reachable: successful)
		
		return (successful, true)
	}
	
	// successful: Connection to AVR successful
	// timeInterval: 'false' if too short after previous execution
	@discardableResult func fetchVolume() -> (volume: Int, successful: Bool, timeInterval: Bool) {
		
		if Date().timeIntervalSince(lastTimeReceive) < 0.05 {
			return (lastVolume, true, false)
		} else {
			lastTimeReceive = Date()
		}
		
		let allowedCharacters = "^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,.-!/()=?`*;:_{}[]\\|~"
		deviceName = deviceName.filter { allowedCharacters.contains($0) }
		let url = URL(string: "http://\(deviceName)/goform/formMainZone_MainZoneXmlStatusLite.xml")
		var successful = true
		
		let semaphore = DispatchSemaphore(value: 0)
		
		let task = session.dataTask(with: url!) { data, _, error in
			guard error == nil else {
//				print(error!) // Should print error anyways, so no need to do it a second time
				successful = false
				semaphore.signal()
				return
			}
			guard let data = data else {
				print("Data is empty")
				successful = false
				semaphore.signal()
				return
			}
			
			let dataString: String = (String(data: data, encoding: String.Encoding.utf8) as String?)!
			
			guard let matchedStringState = dataString.matchingStrings(regex: "<Power><value>(.*)<\\/value><\\/Power>").first?[1] else {
				print("Unexpected Data. Probably not coming from AVR")
				successful = false
				semaphore.signal()
				return
			}
			
			if matchedStringState == "ON" {
				self.lastState = true
			} else if matchedStringState == "OFF" {
				self.lastState = false
			}
			
			guard var matchedStringVolume = dataString.matchingStrings(regex: "<MasterVolume><value>-(.*)<\\/value><\\/MasterVolume>").first?[1] else {
				print("Unexpected Data. Probably not coming from AVR")
				successful = false
				semaphore.signal()
				return
			}
			
			if matchedStringVolume == "-" {
				matchedStringVolume = "80"
			}
			self.lastVolume = 80 - Int(Float(matchedStringVolume)!)
			
			semaphore.signal()
		}
		
		task.resume()
		semaphore.wait()
		
		print("Volume: \(lastVolume)")
		print("State: \(lastState)")
		self.updateUI(volume: lastVolume, state: lastState, reachable: successful)
		
		return (lastVolume, successful, true)
	}
	
	@discardableResult func sendPowerState(state: Bool) -> Bool {
		lastState = state
		let power = state ? "PowerOn" : "PowerStandby"
		
		let url = URL(string: "http://\(deviceName)/goform/formiPhoneAppPower.xml?1+\(power)")
		var successful = true
		
		let semaphore = DispatchSemaphore(value: 0)
		
		let task = session.dataTask(with: url!) { _, _, error in
			guard error == nil else {
				print(error!)
				successful = false
				semaphore.signal()
				return
			}
			
			semaphore.signal()
		}
		
		task.resume()
		semaphore.wait()
		
		print(lastVolume)
		print(lastState)
		self.updateUI(volume: lastVolume, state: state, reachable: successful)
		
		return successful
	}
}
