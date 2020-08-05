//
//  ObservableBLEService.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 8/3/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import Foundation

final class ObservableFoundPeripherals: ObservableObject {
	let id = UUID()
	@Published var foundPeripherals: [BLEPeripheral]

	init(using bleService: BLEService) {
    	self.foundPeripherals = bleService.foundPeripherals
    	
    	Notification.addObserver(self, selector: #selector(handleNotificationFoundPeripheralsChanged), name: BLEManager.NotificationId.bleManagerFoundPeripheralsChanged)
	}
	
	@objc func handleNotificationFoundPeripheralsChanged(_ notification: Foundation.Notification) {
		guard let newFoundPeripherals = notification.object as? [BLEPeripheral] else {
			print("\(#function) - notification.object as? [BLEPeripheral] ==  nil!")
			return
		}
    	self.foundPeripherals = newFoundPeripherals
	}
}
