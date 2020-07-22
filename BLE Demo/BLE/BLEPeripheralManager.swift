//
//  BLEPeripheralManager.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import CoreBluetooth

final class BLEPeripheralManager: NSObject {

	// MARK: Peripheral errors
	enum PeripheralError: String {
		case couldNotConnect = "General.CouldNotConnect"
		case lowBattery = "General.LowBattery"
	}

	enum BloodGlucoseError: String {
		case error = "bloodGlucose.Error"
	}

	enum BloodPressureError: String {
		case invalidMeasurement = "bloodPressure.InvalidMeasurement"
		case bodyMovementDuringMeasurement = "bloodPressure.BodyMovementDuringMeasurement"
		case cuffTooLoose = "bloodPressure.CuffTooLoose"
		case irregularPulseDetected = "bloodPressure.IrregularPulseDetected"
		case pulseRateExceedsUpperLimit = "bloodPressure.PulseRateExceedsUpperLimit"
		case pulseRateIsLessThanLowerLimit = "bloodPressure.PulseRateIsLessThanLowerLimit"
		case improperMeasurementPosition = "bloodPressure.ImproperMeasurementPosition"
	}

	enum StepCountError: String {
		case error = "stepCount.Error"
	}

	enum BloodOxygenError: String {
		case error = "bloodOxygen.Error"
	}

	enum WeightError: String {
		case error = "weight.Error"
	}

	enum Error {
		case bloodGlucose(BloodGlucoseError)
		case bloodOxygen(BloodOxygenError)
		case bloodPressure(BloodPressureError)
		case peripheral(PeripheralError)
		case stepCount(StepCountError)
		case weight(WeightError)
	}

	// MARK: Stored Properties
	private var bleService: BLEService
	private var delegate: BLEPeripheralManagerDelegate
	private var notificationsEnabled = false {
		didSet {
			print(self.notificationsEnabled)
		}
	}

	// MARK: Computed Properties
	internal var observer: PeripheralObserver? {
		get {
			return delegate.observer
		}

		set {
			delegate.observer = newValue
		}
	}

	internal var bluetoothStatus: BluetoothStatus {
		get {
			return delegate.bluetoothStatus
		}
	}

	internal var peripheralName: String {
		return delegate.peripheralName()
	}

	// MARK: Initializers
	internal init(bleService: BLEService, delegate: BLEPeripheralManagerDelegate) {
		self.bleService = bleService
		self.delegate = delegate

		super.init()
	}

	deinit {
		Notification.removeObserver(self)
	}

	// MARK: Methods
	internal func triggerBluetoothPoweredOffAlert() -> Bool {
		return delegate.triggerBluetoothPoweredOffAlert()
	}

	internal func serviceUUIDs() -> [String] {
		return delegate.serviceUUIDs()
	}

	internal func startScanningFor() {
		print("\(self.delegate.peripheralName())")
		enableNotifications()
		delegate.startScanningFor()
	}

	internal func stopScanningFor() {
		print("\(self.delegate.peripheralName())")
		delegate.stopScanningFor()
		disableNotifications()
	}

	internal func enableNotifications() {
		if !notificationsEnabled {
			Notification.addObserver(self, selector: #selector(handleNotificationCentralManagerDidUpdateState(_:)), name: BLEManager.NotificationId.bleCentralDidUpdateState)
			Notification.addObserver(self, selector: #selector(handleNotificationDidConnectPeripheral(_:)), name: BLEManager.NotificationId.bleCentralDidConnectPeripheral)
			Notification.addObserver(self, selector: #selector(handleNotificationDidDisconnectPeripheral(_:)), name: BLEManager.NotificationId.bleCentralDidDisconnectPeripheral)
			Notification.addObserver(self, selector: #selector(handleNotificationDidDiscoverCharacteristicsForService(_:)), name: BLEManager.NotificationId.blePeripheralDidDiscoverCharacteristicsForService)
			Notification.addObserver(self, selector: #selector(handleNotificationDidDiscoverPeripheral(_:)), name: BLEManager.NotificationId.bleCentralDidDiscoverPeripheral)
			Notification.addObserver(self, selector: #selector(handleNotificationDidDiscoverServices(_:)), name: BLEManager.NotificationId.blePeripheralDidDiscoverServices)
			Notification.addObserver(self, selector: #selector(handleNotificationDidFailToConnectPeripheral), name: BLEManager.NotificationId.bleCentralDidFailToConnectPeripheral)
			Notification.addObserver(self, selector: #selector(handleNotificationDidUpdateNotificationStateForCharacteristic(_:)), name: BLEManager.NotificationId.blePeripheralDidUpdateNotificationStateForCharacteristic)
			Notification.addObserver(self, selector: #selector(handleNotificationDidUpdateValueForCharacteristic(_:)), name: BLEManager.NotificationId.blePeripheralDidUpdateValueForCharacteristic)

			notificationsEnabled = true
		}
	}

	internal func disableNotifications() {
		Notification.removeObserver(self)
		notificationsEnabled = false
	}

	@objc internal func handleNotificationCentralManagerDidUpdateState(_ notification: Foundation.Notification) {
		delegate.handleNotificationCentralManagerDidUpdateState(bleService.bluetoothStatus)
	}

	@objc internal func handleNotificationDidDiscoverPeripheral(_ notification: Foundation.Notification) {
		print(#function)
		guard let peripheralDictionary = notification.object as? Dictionary<String, Any> else {
			return
		}
		guard let peripheral = peripheralDictionary["peripheral"] as? CBPeripheral else {
			return
		}
		print("name = \(String(describing: peripheral.name))")
		guard let peripheralName = peripheral.name else {
			return
		}
		guard delegate.isPeripheralSupported(peripheralName) else {
			return
		}

		bleService.connectPeripheral(peripheral)
	}

	@objc internal func handleNotificationDidConnectPeripheral(_ notification: Foundation.Notification) {
		print(#function)
		guard let peripheral = notification.object as? CBPeripheral else {
			return
		}
		print("name = \(String(describing: peripheral.name))")
		guard let peripheralName = peripheral.name else {
			return
		}
		guard delegate.isPeripheralSupported(peripheralName) else {
			return
		}

		bleService.stopScanning()

		delegate.observer?.blePeripheralDidConnectValidPeripheral()
		peripheral.discoverServices(nil)

		delegate.handleNotificationDidConnectPeripheral(notification)
	}

	@objc internal func handleNotificationDidFailToConnectPeripheral() {
		print(#function)
		delegate.observer?.blePeripheralDidErrorConnectingToPeripheral(BLEPeripheralManager.Error.peripheral(.couldNotConnect))
	}
	
	@objc internal func handleNotificationDidDisconnectPeripheral(_ notification: Foundation.Notification) {
		print(#function)
		guard let peripheral = notification.object as? CBPeripheral else {
			return
		}
		print("name = \(String(describing: peripheral.name))")
		
		delegate.handleNotificationDidDisconnectPeripheral(notification)
		
		delegate.observer?.bleCentralDidDisconnectPeripheral()
	}

	@objc internal func handleNotificationDidDiscoverServices(_ notification: Foundation.Notification) {
		print(#function)
		guard let peripheral = notification.object as? CBPeripheral else {
			return
		}
		print("name = \(String(describing: peripheral.name))")
		guard let serviceArray = peripheral.services else {
			return
		}
		for service in serviceArray {
			print("service = \(service)")
			print("service.UUID = \(service.uuid)")
		}
	}

	@objc internal func handleNotificationDidDiscoverCharacteristicsForService(_ notification: Foundation.Notification) {
		print(#function)
		guard let dictionary = notification.object as? Dictionary<String, Any> else {
			return
		}
		guard let service = dictionary["service"] as? CBService else {
			return
		}
		guard let peripheral = dictionary["peripheral"] as? CBPeripheral else {
			return
		}
		print("name = \(String(describing: peripheral.name))")
		print("service = \(service)")
		guard let characteristicArray = service.characteristics else {
			return
		}
		print("characteristics = \(characteristicArray.description)")

		for characteristic in characteristicArray {
			delegate.handleNotificationDidDiscoverCharacteristicsForService(peripheral, characteristic: characteristic)
		}
	}

	@objc internal func handleNotificationDidUpdateNotificationStateForCharacteristic(_ notification: Foundation.Notification) {
		// called in response to setNotifyValue
		print(#function)
		guard let dictionary = notification.object as? Dictionary<String, Any> else {
			return
		}
		guard let peripheral = dictionary["peripheral"] as? CBPeripheral else {
			return
		}
		guard let characteristic = dictionary["characteristic"] as? CBCharacteristic else {
			return
		}

		print("name = \(String(describing: peripheral.name))")
		print("characteristic = \(characteristic)")
		let characteristicProperties = characteristic.properties
		print("characteristicProperties = \(characteristicProperties)")

		delegate.handleNotificationDidUpdateNotificationStateForCharacteristic(peripheral, characteristic: characteristic)
	}

	@objc internal func handleNotificationDidUpdateValueForCharacteristic(_ notification: Foundation.Notification) {
		// called in response to readValueForCharacteristic
		print(#function)
		guard let dictionary = notification.object as? Dictionary<String, Any> else {
			return
		}
		guard let peripheral = dictionary["peripheral"] as? CBPeripheral else {
			return
		}
		guard let characteristic = dictionary["characteristic"] as? CBCharacteristic else {
			return
		}
		print("name = \(String(describing: peripheral.name))")
		print("characteristic = \(characteristic)")
		guard characteristic.value != nil else {
			return
		}

		delegate.handleNotificationDidUpdateValueForCharacteristic(characteristic)
	}
}
