//
//  BLEPeripheralManagerFactoryService.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import Foundation

enum PeripheralType {
	case bloodGlucose
	case bloodOxygen
	case bloodPressure
	case stepCount
	case weight
	case heartRate
	case peakExpiratoryFlow
	case lungCapacity
	case temperature
}

protocol BLEPeripheralManagerFactoryService {
	func createPeripheralManager(for: PeripheralType, using bleService: BLEService) -> BLEPeripheralManager
}
