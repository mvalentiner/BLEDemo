//
//  ScaleScreenViewController.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import Foundation

class ScaleScreenViewController {

	fileprivate let bleWeightScale = BLEPeripheralManagerFactory().createPeripheralManager(for: .weight, using: ServiceRegistry.bleService)

	internal var isComplete: Bool = false

	internal func startScanningForWeight() -> Bool {

		switch bleWeightScale.bluetoothStatus {
		case .notAvailableOnDevice:
			return false

		case .pending:
			return false

		case .poweredOn:
			bleWeightScale.startScanningFor()
			return true

		case .poweredOff:
			return false
		}
	}

	internal func stopScanningForWeight() -> Bool {

		switch bleWeightScale.bluetoothStatus {
		case .notAvailableOnDevice:
			return false

		case .pending:
			return false

		case .poweredOn:
			bleWeightScale.stopScanningFor()
			return true

		case .poweredOff:
			return false
		}
	}
}
