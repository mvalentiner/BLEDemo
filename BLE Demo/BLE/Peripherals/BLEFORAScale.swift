//
//  BLEFORAScale.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import CoreBluetooth

/**
 *	Concrete BLEScale implementation for FORA TNG weight scale peripheral.
 */
final internal class BLEFORAScale: BLEPeripheralManagerDelegateBase, BLEPeripheralManagerDelegate {

	// MARK: Stored Properties
	private let characteristicId = "00001524-1212-EFDE-1523-785FEABCD123"
	private let responseBytes = NSMutableData()
	private let serviceId = "1809"  // FORA TNG weight scale advertises as a Health Thermometer
	private let tngScaleName = "TNG SCALE"

	// MARK: Methods
	internal func characteristicUUID() -> String {
		return characteristicId
	}

	internal func peripheralName() -> String {
		return tngScaleName
	}

	internal func serviceUUIDs() -> [String] {
		return [serviceId]
	}

	internal func handleNotificationDidDiscoverCharacteristicsForService(_ peripheral: CBPeripheral, characteristicArray: [CBCharacteristic]) {
		responseBytes.length = 0
	}

	internal func handleNotificationDidUpdateNotificationStateForCharacteristic(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		responseBytes.length = 0
		sendReadCommandToPeripheral(peripheral, forCharacteristic: characteristic)
	}

	internal func handleNotificationDidUpdateValueForCharacteristic(_ characteristic: CBCharacteristic) {
		let responseData = characteristic.value!
		print("value = " + responseData.description)
		responseBytes.append(responseData)

		let responseDataBytes = (responseData as NSData).bytes.bindMemory(to: UInt8.self, capacity: responseData.count)
		if responseDataBytes[0] == 0xA5 {

			processResponseData(responseBytes as Data)
			disconnectPeripheral()
		}
	}

	private func sendReadCommandToPeripheral(_ peripheral: CBPeripheral, forCharacteristic: CBCharacteristic) {
		print("ScaleViewController.sendReadCommandToPeripheral")

		let readFrame: [UInt8] = [0x51, 0x71, 0x02, 0x00, 0x00, 0xA3, 0x67]
//		var checkSum : UInt = 0
//		for n in readFrame {
//			checkSum += UInt(n)
//		}
//		readFrame[6] = UInt8(truncatingBitPattern: checkSum)
		let readCommand = Data(bytes: UnsafePointer<UInt8>(readFrame), count: readFrame.count)
		print("readCommand = " + readCommand.description)
		print("readFrame.count = " + String(readFrame.count))
		peripheral.writeValue(readCommand, for: forCharacteristic, type: .withResponse)
	}

	private func sendTurnOffDeviceCommand(_ peripheral: CBPeripheral, forCharacteristic: CBCharacteristic) {
		print("ScaleViewController.sendTurnOffDeviceCommand")

		let turnOffFrame: [UInt8] = [0x51, 0x50, 0x00, 0x00, 0x00, 0x00, 0xA1]
		let turnOffCommand = Data(bytes: UnsafePointer<UInt8>(turnOffFrame), count: turnOffFrame.count)
		print("turnOffCommand = " + turnOffCommand.description)
		print("turnOffFrame.count = " + String(turnOffFrame.count))
		peripheral.writeValue(turnOffCommand, for: forCharacteristic, type: .withResponse)
	}

	private func processResponseData(_ responseData: Data) {

		print("responseData = " + responseData.description)

		let dataBytes = (responseData as NSData).bytes.bindMemory(to: UInt8.self, capacity: responseData.count)

		// Kilograms
		let kgHighByte = responseData[18]
		let kgLowByte = responseData[19]
		let kgDataShort = [kgLowByte, kgHighByte]
		print("kgDataShort = " + String(describing: kgDataShort))

		var measurementValueArray: [MeasurementValue] = []
		let _ = UnsafePointer(kgDataShort).withMemoryRebound(to: UInt16.self, capacity: 1) {
			let kilograms = Double(Int($0.pointee)) / 10.0
			print("kilograms = " + String(kilograms))

			let kilogramsValue = MeasurementValue(unit: .weight(.kilograms), doubleValue: kilograms)
			measurementValueArray.append(kilogramsValue)
		}
		// Pounds
		let lbHighByte = (dataBytes + 20)[0]
		let lbLowByte = (dataBytes + 21)[0]
		let lbDataShort = [lbLowByte, lbHighByte]
		print("lbDataShort = " + String(describing: lbDataShort))

		let _ = UnsafePointer(lbDataShort).withMemoryRebound(to: UInt16.self, capacity: 1) {
			let pounds = Double(Int($0.pointee)) / 10.0
			print("pounds = " + String(pounds))

			let poundsValue = MeasurementValue(unit: .weight(.pounds), doubleValue: pounds)
			measurementValueArray.append(poundsValue)
		}

		self.observer?.blePeripheralDidUpdateValue(readings: measurementValueArray)
	}
}
/*
Stream Byte	FrameByte	Description
0		Data index 		
1		0		
2	1	CMD		
3	2	ACK		
4	3	Length		
5	4	Stable time		
6	5	Year		
7	6	Month		
8	7	Day		
9	8	Hour		
10	9	Minute		
11	10	Code/UserId		
12	11	Gender		
13	12	Height (cm)		
14	13	Height (in) x10 high byte		
15	14	Height (in) x10 low byte		
16	15	Age		
17	16	Cal Unit		
18	17	weight in kg x10 high byte
19	18	weight in kg x10 low byte
20	19	weight in lb x10 high byte
21	20	weight in lb x10 low byte
22	21	BMI % x10 high byte		
23	22	BMI % x10 low byte		
24	23	BMI Kcal/day high byte		
25	24	BMI Kcal/day low byte		
26	25	Body Fat. Bf% x10 high byte		
27	26	Body Fat. Bf% x10 low byte		
28	27	Body muscle. Bm% x10 high byte		
29	28	Body muscle. Bm% x10 low byte		
30	29	Body bone. Bn% x10.		
31	30	Body water. Bw% x10 high byte		
32	31	Body water. Bw% x10 low byte		
33	32	Body Fat Status
*/
