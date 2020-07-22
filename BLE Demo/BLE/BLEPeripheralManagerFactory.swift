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
//			return BLEPeripheralManager(delegate: BLEAccuChekGlucoseMonitor())
			fatalError("Unsupported Peripheral Type")

		case .bloodOxygen:
//			return BLEPeripheralManager(delegate: BLENoninPulseOximeter())
			fatalError("Unsupported Peripheral Type")

		case .bloodPressure:
//			return BLEPeripheralManager(delegate: BLEAnDBloodPressureMonitor())
			fatalError("Unsupported Peripheral Type")

		case .stepCount:
//				return BLEPeripheralManager(delegate: BLEGarminVivofit2())
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
