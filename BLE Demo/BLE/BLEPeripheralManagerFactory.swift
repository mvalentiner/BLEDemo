//
//  BLEPeripheralManagerFactory.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

internal struct BLEPeripheralManagerFactory: BLEPeripheralManagerFactoryService {

	// MARK: Methods
	internal func createPeripheralManager(for deviceType: PeripheralType, using bleService: BLEService) -> BLEPeripheralManager {

		switch deviceType {
		case .bloodGlucose:
			fatalError("Unsupported Peripheral Type")

		case .bloodOxygen:
			fatalError("Unsupported Peripheral Type")

		case .bloodPressure:
			fatalError("Unsupported Peripheral Type")

		case .stepCount:
			fatalError("Unsupported Peripheral Type")

		case .weight:
			return BLEPeripheralManager(bleService: bleService, delegate: BLEFORAScale(bleService: bleService))

		case .heartRate:
			fatalError("Unsupported Peripheral Type")

		case .peakExpiratoryFlow:
			fatalError("Unsupported Peripheral Type")

		case .lungCapacity:
			fatalError("Unsupported Peripheral Type")

		case .temperature:
			fatalError("Unsupported Peripheral Type")
		}
	}
}
