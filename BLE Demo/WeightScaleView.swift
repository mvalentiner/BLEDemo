//
//  ContentView.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import CoreBluetooth
import SwiftUI

struct ScanScreen: View {

	let startScanning: ([CBUUID]) -> Void

	@ObservedObject var peripherals: ObservableFoundPeripherals

	init(using startScanning: @escaping ([CBUUID]) -> Void, peripherals: ObservableFoundPeripherals) {
		self.startScanning = startScanning
		self.peripherals = peripherals
	}

	let scaleDevices: [WeightScale] = []

    var body: some View {
		VStack(alignment: .leading) {
			Button(action: {
				self.startScanning([])
			}) {
				Text("Scan")
			}
			NavigationView {
				List(peripherals.foundPeripherals) { scale in
					NavigationLink(destination: Text(scale.name)) {
						Text(scale.name)
					}
				}
				.navigationBarTitle(Text("Weight Scales"))
			}
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ScanScreen(using: {_ in }, peripherals: ObservableFoundPeripherals(using: ServiceRegistry.bleService))
    }
}
