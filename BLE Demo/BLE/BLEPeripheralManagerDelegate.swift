//
//  BLEPeripheralManagerDelegate.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import CoreBluetooth

protocol PeripheralObserver: class {

	// MARK: Methods
	func bleCentralDidDisconnectPeripheral()

	func bleCentralDidUpdateBluetoothEnabled(_ bluetoothStatus: BluetoothStatus)

	func blePeripheralDidComplete()

	func blePeripheralDidConnectValidPeripheral()

	func blePeripheralDidErrorConnectingToPeripheral(_ error: BLEPeripheralManager.Error)

	func blePeripheralDidNotReceiveNewValues()

	func blePeripheralDidReceiveError(_ error: BLEPeripheralManager.Error)

	func blePeripheralDidUpdateValue(readings: [MeasurementValue])
}

/**
	Protocol that all BLEPeripheralDelegates must implement
*/
protocol BLEPeripheralManagerDelegate: class {

	// MARK: Properties
	var bleService: BLEService { get }

	var bluetoothStatus: BluetoothStatus { get }

	var observer: PeripheralObserver? { get set }

	var peripheral: CBPeripheral? { get set }

	// MARK: Methods
	func characteristicUUID() -> String

	func handleHealthCheckSubmissionSuccessful()

	func handleNotificationCentralManagerDidUpdateState(_ bluetoothStatus: BluetoothStatus)

	func handleNotificationDidConnectPeripheral(_ notification: Foundation.Notification)

	func handleNotificationDidDisconnectPeripheral(_ notification: Foundation.Notification)

	func handleNotificationDidUpdateBluetoothEnabled(_ bluetoothStatus: BluetoothStatus)

	func handleNotificationDidDiscoverCharacteristicsForService(_ peripheral: CBPeripheral, characteristic: CBCharacteristic)

	func handleNotificationDidUpdateNotificationStateForCharacteristic(_ peripheral: CBPeripheral, characteristic: CBCharacteristic)

	func handleNotificationDidUpdateValueForCharacteristic(_ characteristic: CBCharacteristic)

	func isPeripheralSupported(_ peripheralName: String) -> Bool

	func peripheralName() -> String

	func serviceUUIDs() -> [String]

	func startScanningFor()

	func stopScanningFor()

	func triggerBluetoothPoweredOffAlert() -> Bool
}

/**
	This protocol extension provides a customization point where we add default implementation for BLEPeripheralDelegates
*/
extension BLEPeripheralManagerDelegate {

	// MARK: Computed Properties
	internal var bluetoothStatus: BluetoothStatus {
		return bleService.bluetoothStatus
	}

	// MARK: Methods
	internal func disconnectPeripheral() {
		if let peripheral = self.peripheral {
			bleService.disconnectPeripheral(peripheral)
		}
	}

	internal func triggerBluetoothPoweredOffAlert() -> Bool {
		return bleService.triggerBluetoothPoweredOffAlert()
	}

	internal func handleHealthCheckSubmissionSuccessful() {
		print("empty, default implementation")
	}

	internal func isPeripheralSupported(_ foundPeripheralName: String) -> Bool {
		guard foundPeripheralName == peripheralName() else {
			return false
		}
		return true
	}

	internal func handleNotificationCentralManagerDidUpdateState(_ bluetoothStatus: BluetoothStatus) {
		print(#function)
		observer?.bleCentralDidUpdateBluetoothEnabled(bluetoothStatus)
		if bluetoothStatus == .poweredOn {
			startScanningFor()
		}
	}

	internal func handleNotificationDidUpdateBluetoothEnabled(_ bluetoothStatus: BluetoothStatus) {
		self.observer?.bleCentralDidUpdateBluetoothEnabled(bluetoothStatus)
	}
	
	internal func handleNotificationDidConnectPeripheral(_ notification: Foundation.Notification) {
		guard let peripheral = notification.object as? CBPeripheral else {
			return
		}
		
		self.peripheral = peripheral
	}
	
	internal func handleNotificationDidDisconnectPeripheral(_ notification: Foundation.Notification) {
		self.startScanningFor()
	}

	internal func handleNotificationDidDiscoverCharacteristicsForService(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		guard characteristic.uuid.uuidString == characteristicUUID() else {
			return
		}
		print("foundCharacteristic = \(characteristic.description)")
		peripheral.setNotifyValue(true, for: characteristic)
	}

	internal func handleNotificationDidUpdateNotificationStateForCharacteristic(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		print("characteristic = \(characteristic.description)")
	}

	internal func handleNotificationDidUpdateValueForCharacteristic(_ characteristic: CBCharacteristic) {
		print("characteristic = \(characteristic.description)")
	}

	internal func startScanningFor() {
		var cbUUIDs : [CBUUID] = []
		for serviceId in self.serviceUUIDs() {
			cbUUIDs.append(CBUUID(string: serviceId))
		}
		if !cbUUIDs.isEmpty {
			bleService.startScanning(cbUUIDs)
		}
		else {
			bleService.startScanning([])
		}
	}

	internal func stopScanningFor() {
		bleService.stopScanning()
	}
}

class BLEPeripheralManagerDelegateBase {

	internal var bleService: BLEService
	internal weak var observer: PeripheralObserver?
	internal var peripheral: CBPeripheral?
	
	init(bleService: BLEService) {
		self.bleService = bleService
	}
}
