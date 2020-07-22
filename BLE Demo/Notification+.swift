//
//  Notification+.swift
//  BLE Demo
//
//  Created by Michael Valentiner on 7/22/20.
//  Copyright © 2020 Heliotropix, LLC. All rights reserved.
//

import Foundation

import Foundation

extension Notification {

	// MARK: Methods
	internal static func addObserver(_ observer: Any, selector aSelector: Selector, name aName: Notification.Name, object anObject: Any? = nil) {
		NotificationCenter.default.addObserver(observer, selector: aSelector, name: aName, object: anObject)
	}

	internal static func post(name: Notification.Name, object anObject: Any? = nil) {
		NotificationCenter.default.post(name: name, object: anObject)
	}


	internal static func removeObserver(_ observer: Any) {
		NotificationCenter.default.removeObserver(observer)
	}
}
