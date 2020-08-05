//
//  ScaleScreen.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 8/4/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import SwiftUI

struct ScaleScreen: View {

	let scale: WeightScale

	init(with scale: WeightScale) {
		self.scale = scale
	}

    var body: some View {
		VStack(alignment: .leading) {
			Text(scale.title)
			Button(action: {
			}) {
				Text("Sync")
			}
		}
//			NavigationView {
//				List(peripherals.foundPeripherals) { scale in
//					NavigationLink(destination: Text(scale.name)) {
//						Text(scale.name)
//					}
//				}
//				.navigationBarTitle(Text("Weight Scales"))
//			}
//		}
    }
}

struct ScaleScreen_Previews: PreviewProvider {
    static var previews: some View {
		ScaleScreen(with: WeightScale(title: "Mock Scale"))
    }
}
