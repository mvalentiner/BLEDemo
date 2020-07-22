//
//  BLEManager.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import CoreBluetooth


private struct BLEServiceName {
	static let serviceName = "BLEService"
}

extension ServiceRegistryImplementation {
	var bleService : BLEService {
		get {
			return serviceWith(name: BLEServiceName.serviceName) as! BLEService	// Intentional force unwrapping
		}
	}
}

protocol BLEService : SOAService {
	var bluetoothStatus: BluetoothStatus { get }

	func triggerBluetoothPoweredOffAlert() -> Bool
	func connectPeripheral(_ peripheral: CBPeripheral)
	func disconnectPeripheral(_ peripheral: CBPeripheral)
	func startScanning(_ serviceUUIDs: [CBUUID])
	func stopScanning()

}

extension BLEService {
	var serviceName : String {
		get {
			return BLEServiceName.serviceName
		}
	}
}

/**
 *	A wrapper around CoreBluetooth that provides a single implementation that maintains state across multiple UIViewControllers
 */
final class BLEManager: NSObject, BLEService {

	static func register() {
		BLEManager().register()
	}

	// MARK: Stored Properties
	internal struct NotificationId {
		internal static var bleCentralDidConnectPeripheral: Notification.Name { return Notification.Name(#function) }

		internal static var bleCentralDidDisconnectPeripheral: Notification.Name { return Notification.Name(#function) }

		internal static var bleCentralDidDiscoverPeripheral: Notification.Name { return Notification.Name(#function) }

		internal static var bleCentralDidFailToConnectPeripheral: Notification.Name { return Notification.Name(#function) }

		internal static var bleCentralDidUpdateState: Notification.Name { return Notification.Name(#function) }

		internal static var bleManagerFoundPeripheralsChanged: Notification.Name { return Notification.Name(#function) }

		internal static var blePeripheralDidDiscoverCharacteristicsForService: Notification.Name { return Notification.Name(#function) }

		internal static var blePeripheralDidDiscoverServices: Notification.Name { return Notification.Name(#function) }

		internal static var blePeripheralDidUpdateNotificationStateForCharacteristic: Notification.Name { return Notification.Name(#function) }

		internal static var blePeripheralDidUpdateValueForCharacteristic: Notification.Name { return Notification.Name(#function) }
	}

	internal var foundPeripherals = Array<Dictionary<String, Any>>()
	private var centralManager: CBCentralManager!

	// MARK: Stored Properties
	internal var bluetoothStatus: BluetoothStatus {
		return BluetoothStatus(state: centralManager.state)
	}

	// MARK: Initializers
	override init() {
		super.init()

		centralManager = createCentralManager(showBluetoothAlertIfPoweredOff: false)
	}

	// MARK: Methods

	/**
	 *	Reallocate a CBCentralManager to trigger the system alert notifying the user BLE is powered off.
	 */
	internal func triggerBluetoothPoweredOffAlert() -> Bool {

		let state = centralManager.state
		guard state == .poweredOff else {

			// Triggering the Bluetooth alert will only work if centralManager.state is 'PoweredOff'.
			print("Triggering the system Bluetooth alert aborted since centralManager.state is \(String(state.rawValue)) not 'PoweredOff'.")

			if state == .unknown {
				print("centralManager.state 'Unknown' is indeterminate and suggests an update is imminent.")
			}
			else if state == .resetting {
				print("centralManager.state 'Resetting' is indeterminate and suggests an update is imminent.")
			}
			else if state == .unsupported {
				print("Bluetooth not supported on this device. Note: Bluetooth is not supported on the iOS simulator. You can enable mock peripherals to test on the simulator.")
			}
			else if state == .unauthorized {
				print("Bluetooth not authorized for this app. This is a configuration issue.")
			}

			return false
		}

		print("Creating new CBCentralManager to trigger Bluetooth alert")
		centralManager = createCentralManager(showBluetoothAlertIfPoweredOff: true)
		return true
	}

	internal func startScanning(_ serviceUUIDs: [CBUUID] = []) {
		foundPeripherals.removeAll()

		Notification.post(name: BLEManager.NotificationId.bleManagerFoundPeripheralsChanged, object: foundPeripherals)

		if #available(iOS 10.0, *) {
			guard centralManager.state == CBManagerState.poweredOn else {
				return
			}
		}
		else {
			guard CBCentralManagerState(rawValue: (centralManager.state.rawValue)) == CBCentralManagerState.poweredOn else {
				return
			}
		}

		centralManager.stopScan()

		let optionsDictionary = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: false as Bool)]
		centralManager.scanForPeripherals(withServices: serviceUUIDs, options: optionsDictionary)
	}

	internal func stopScanning() {
		centralManager.stopScan()
	}

	internal func connectPeripheral(_ peripheral: CBPeripheral) {
		print(#function)
		peripheral.delegate = self
		let optionsDictionary = [
			CBConnectPeripheralOptionNotifyOnConnectionKey: NSNumber(value: true as Bool),
			CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(value: true as Bool),
			CBConnectPeripheralOptionNotifyOnNotificationKey: NSNumber(value: true as Bool)
		]
		centralManager.connect(peripheral, options: optionsDictionary)
	}

	internal func disconnectPeripheral(_ peripheral: CBPeripheral) {
		print(#function)
		peripheral.delegate = nil
		centralManager.cancelPeripheralConnection(peripheral)
	}

	private func createCentralManager(showBluetoothAlertIfPoweredOff: Bool) -> CBCentralManager {
		return CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: showBluetoothAlertIfPoweredOff])
	}

	private func retrievePeripheralsWithIdentifiers(_ identifiers: [UUID]) -> [CBPeripheral] {
		if #available(iOS 10.0, *) {
			guard centralManager.state == CBManagerState.poweredOn else {
				foundPeripherals.removeAll()
				Notification.post(name: BLEManager.NotificationId.bleManagerFoundPeripheralsChanged, object: foundPeripherals)
				return []
			}
		}
		else {
			guard CBCentralManagerState.init(rawValue: centralManager.state.rawValue) == CBCentralManagerState.poweredOn else {
				foundPeripherals.removeAll()
				Notification.post(name: BLEManager.NotificationId.bleManagerFoundPeripheralsChanged, object: foundPeripherals)
				return []
			}
		}

		return centralManager.retrievePeripherals(withIdentifiers: identifiers)
	}
}

extension BLEManager: CBCentralManagerDelegate {
	// MARK: CBCentralManagerDelegate Implementation

	internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
		print("central.state: \(String(central.state.rawValue))")

		if central.state == .unsupported {
			print("Bluetooth not supported on this device. Note: Bluetooth is not supported on the iOS simulator. You can enable mock peripherals to test on the simulator.")
		}
		else if central.state == .unauthorized {
			print("Bluetooth not authorized for this app. This is a configuration issue.")
		}

		Notification.post(name: BLEManager.NotificationId.bleCentralDidUpdateState)
	}

	/**
	 *  @method centralManager:willRestoreState:
	 *
	 *  @param central      The central manager providing this information.
	 *  @param dictionary			A dictionary containing information about <i>central</i> that was preserved by the system at the time the app was terminated.
	 *
	 *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
	 *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
	 *						Bluetooth system.
	 *
	 *  @seealso            CBCentralManagerRestoredStatePeripheralsKey;
	 *  @seealso            CBCentralManagerRestoredStateScanServicesKey;
	 *  @seealso            CBCentralManagerRestoredStateScanOptionsKey;
	 *
	 */
	internal func centralManager(_ central: CBCentralManager, willRestoreState dictionary: [String: Any]) {
		print(#function)
	}

	/**
	 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
	 *
	 *  @param central              The central manager providing this update.
	 *  @param peripheral           A <code>CBPeripheral</code> object.
	 *  @param advertisementData    A dictionary containing any advertisement and scan response data.
	 *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
	 *								was not available.
	 *
	 *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must
	 *                              be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For
	 *                              a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
	 *
	 *  @seealso                    CBAdvertisementData.h
	 *
	 */
	internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
		print(#function)

		// Don't add if we already know this peripheral
		let foundId = peripheral.identifier
		for knownPeripheralDictionary in foundPeripherals {
			if let knownPeripheral = knownPeripheralDictionary["peripheral"] as? CBPeripheral {
				if knownPeripheral.identifier == foundId {
					print("peripheral already known: \(String(describing: peripheral.name))")
					return
				}
			}
		}
		print("name = \(String(describing: peripheral.name))")
		print("peripheral = \(peripheral)")
		print("identifier = \(peripheral.identifier)")

		var peripheralDictionary = Dictionary<String, Any>()
		peripheralDictionary["peripheral"] = peripheral
		peripheralDictionary["advertisementData"] = advertisementData
		peripheralDictionary["RSSI"] = RSSI
		foundPeripherals.append(peripheralDictionary)
		Notification.post(name: BLEManager.NotificationId.bleManagerFoundPeripheralsChanged, object: foundPeripherals)
		Notification.post(name: BLEManager.NotificationId.bleCentralDidDiscoverPeripheral, object: peripheralDictionary)
	}

	/**
	 *  @method centralManager:didConnectPeripheral:
	 *
	 *  @param central      The central manager providing this information.
	 *  @param peripheral   The <code>CBPeripheral</code> that has connected.
	 *
	 *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has succeeded.
	 *
	 */
	internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print(#function)
		Notification.post(name: BLEManager.NotificationId.bleCentralDidConnectPeripheral, object: peripheral)
	}

	/**
	 *  @method centralManager:didFailToConnectPeripheral:error:
	 *
	 *  @param central      The central manager providing this information.
	 *  @param peripheral   The <code>CBPeripheral</code> that has failed to connect.
	 *  @param error        The cause of the failure.
	 *
	 *  @discussion         This method is invoked when a connection initiated by {@link connectPeripheral:options:} has failed to complete. As connection attempts do not
	 *                      timeout, the failure of a connection is atypical and usually indicative of a transient issue.
	 *
	 */
	internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		print(#function)
		Notification.post(name: BLEManager.NotificationId.bleCentralDidFailToConnectPeripheral, object: peripheral)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
	}

	/**
	 *  @method centralManager:didDisconnectPeripheral:error:
	 *
	 *  @param central      The central manager providing this information.
	 *  @param peripheral   The <code>CBPeripheral</code> that has disconnected.
	 *  @param error        If an error occurred, the cause of the failure.
	 *
	 *  @discussion         This method is invoked upon the disconnection of a peripheral that was connected by {@link connectPeripheral:options:}. If the disconnection
	 *                      was not initiated by {@link cancelPeripheralConnection}, the cause will be detailed in the <i>error</i> parameter. Once this method has been
	 *                      called, no more methods will be invoked on <i>peripheral</i>'s <code>CBPeripheralDelegate</code>.
	 *
	 */
	internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		print(#function)
		Notification.post(name: BLEManager.NotificationId.bleCentralDidDisconnectPeripheral, object: peripheral)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
	}
}

extension BLEManager: CBPeripheralDelegate {
	// MARK: CBPeripheralDelegate Implementation

	/**
	 *  @method peripheral:didModifyServices:
	 *
	 *  @param peripheral			The peripheral providing this update.
	 *  @param invalidatedServices	The services that have been invalidated
	 *
	 *  @discussion			This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
	 *						At this point, the designated <code>CBService</code> objects have been invalidated.
	 *						Services can be re-discovered via @link discoverServices: @/link.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
		print(#function)
	}

	/**
	 *  @method peripheralDidUpdateRSSI:error:
	 *
	 *  @param peripheral	The peripheral providing this update.
	 *	@param error		If an error occurred, the cause of the failure.
	 *
	 *  @discussion			This method returns the result of a @link readRSSI: @/link call.
	 *
	 *  @deprecated			Use {@link peripheral:didReadRSSI:error:} instead.
	 */
	internal func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
	}

	/**
	 *  @method peripheral:didReadRSSI:error:
	 *
	 *  @param peripheral	The peripheral providing this update.
	 *  @param RSSI			The current RSSI of the link.
	 *  @param error		If an error occurred, the cause of the failure.
	 *
	 *  @discussion			This method returns the result of a @link readRSSI: @/link call.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
	}

	/**
	 *  @method peripheral:didDiscoverServices:
	 *
	 *  @param peripheral	The peripheral providing this information.
	 *	@param error		If an error occurred, the cause of the failure.
	 *
	 *  @discussion			This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
	 *						<i>peripheral</i>'s @link services @/link property.
	 *
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
		for service in peripheral.services! {
			print("didDiscoverServices = \(service.debugDescription)")
			peripheral.discoverCharacteristics(nil, for: service)
		}
		Notification.post(name: BLEManager.NotificationId.blePeripheralDidDiscoverServices, object: peripheral)
	}

	/**
	 *  @method peripheral:didDiscoverIncludedServicesForService:error:
	 *
	 *  @param peripheral	The peripheral providing this information.
	 *  @param service		The <code>CBService</code> object containing the included services.
	 *	@param error		If an error occurred, the cause of the failure.
	 *
	 *  @discussion			This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully,
	 *						they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
	}

	/**
	 *  @method peripheral:didDiscoverCharacteristicsForService:error:
	 *
	 *  @param peripheral	The peripheral providing this information.
	 *  @param service		The <code>CBService</code> object containing the characteristic(s).
	 *	@param error		If an error occurred, the cause of the failure.
	 *
	 *  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
	 *						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}

		let dictionary = ["peripheral": peripheral, "service": service]
		Notification.post(name: BLEManager.NotificationId.blePeripheralDidDiscoverCharacteristicsForService, object: dictionary)
	}

	/**
	 *  @method peripheral:didUpdateValueForCharacteristic:error:
	 *
	 *  @param peripheral		The peripheral providing this information.
	 *  @param characteristic	A <code>CBCharacteristic</code> object.
	 *	@param error			If an error occurred, the cause of the failure.
	 *
	 *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
		let dictionary = ["peripheral": peripheral, "characteristic": characteristic]
		Notification.post(name: BLEManager.NotificationId.blePeripheralDidUpdateValueForCharacteristic, object: dictionary)
	}

	/**
	 *  @method peripheral:didWriteValueForCharacteristic:error:
	 *
	 *  @param peripheral		The peripheral providing this information.
	 *  @param characteristic	A <code>CBCharacteristic</code> object.
	 *	@param error			If an error occurred, the cause of the failure.
	 *
	 *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}

		print("peripheral = \(peripheral.description)")
		print("characteristic = \(characteristic.description)")
	}

	/**
	 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
	 *
	 *  @param peripheral		The peripheral providing this information.
	 *  @param characteristic	A <code>CBCharacteristic</code> object.
	 *	@param error			If an error occurred, the cause of the failure.
	 *
	 *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		print(#function)
		if let error = error {
			print("characteristic = \(characteristic.description)")
			print("error = \(error.localizedDescription)")
			return
		}

		peripheral.delegate = self
		let dictionary = ["peripheral": peripheral, "characteristic": characteristic]
		Notification.post(name: BLEManager.NotificationId.blePeripheralDidUpdateNotificationStateForCharacteristic, object: dictionary)
	}

	/**
	 *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
	 *
	 *  @param peripheral		The peripheral providing this information.
	 *  @param characteristic	A <code>CBCharacteristic</code> object.
	 *	@param error			If an error occurred, the cause of the failure.
	 *
	 *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
	 *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
	}

	/**
	 *  @method peripheral:didUpdateValueForDescriptor:error:
	 *
	 *  @param peripheral		The peripheral providing this information.
	 *  @param descriptor		A <code>CBDescriptor</code> object.
	 *	@param error			If an error occurred, the cause of the failure.
	 *
	 *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
	}

	/**
	 *  @method peripheral:didWriteValueForDescriptor:error:
	 *
	 *  @param peripheral		The peripheral providing this information.
	 *  @param descriptor		A <code>CBDescriptor</code> object.
	 *	@param error			If an error occurred, the cause of the failure.
	 *
	 *  @discussion				This method returns the result of a @link writeValue:forDescriptor: @/link call.
	 */
	internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
		print(#function)
		if let error = error {
			print("error = \(error.localizedDescription)")
			return
		}
	}
}

internal enum BluetoothStatus {
	case notAvailableOnDevice
	case pending
	case poweredOff
	case poweredOn

	internal init(state: CBManagerState) {
		switch state {
		case .unknown:
			self = .pending
		case .resetting:
			self = .pending
		case .unsupported:
			self = .notAvailableOnDevice
		case .unauthorized:
			self = .notAvailableOnDevice
		case .poweredOff:
			self = .poweredOff
		case .poweredOn:
			self = .poweredOn
		@unknown default:
			fatalError(#function + " Unknown CBManagerState case.")
		}
	}
}
