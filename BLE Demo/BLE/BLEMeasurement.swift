//
//  BLEMeasurement.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import Foundation

internal enum MeasurementUnit {
	case weight(WeightUnit)

	internal init(weightUnitString: String) {
		var measurementUnit: MeasurementUnit
		if let weightUnit = WeightUnit(rawValue: weightUnitString) {
			measurementUnit = MeasurementUnit.weight(weightUnit)
		}
		else {
			measurementUnit = MeasurementUnit.weight(WeightUnit.kilograms)
		}
		self = measurementUnit
	}
}

internal enum WeightUnit: String {
	case kilograms = "Kilograms"
	case pounds = "Pounds"
}

internal struct MeasurementValue {

	// MARK: Stored Properties
	internal let unit: MeasurementUnit
	internal let value: Double

	// MARK: Initializers
	internal init(unit: MeasurementUnit, doubleValue: Double) {
		self.unit = unit
		self.value = doubleValue
	}

	internal init(unit: MeasurementUnit, intValue: Int) {
		self.unit = unit
		self.value = Double(intValue)
	}
}
