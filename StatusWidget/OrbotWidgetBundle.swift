//
//  OrbotWidgetBundle.swift
//  StatusWidget
//
//  Created by Benjamin Erhart on 23.06.23.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct OrbotWidgetBundle: WidgetBundle {
    var body: some Widget {
        OrbotWidget()
    }
}

extension View {

	func widgetBackground(_ backgroundView: some View) -> some View {
		if #available(iOSApplicationExtension 17.0, *) {
			return containerBackground(for: .widget) {
				backgroundView
			}
		}
		else {
			return background(backgroundView)
		}
	}
}
