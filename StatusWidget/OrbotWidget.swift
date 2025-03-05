//
//  OrbotWidget.swift
//  StatusWidget
//
//  Created by Benjamin Erhart on 23.06.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
	func placeholder(in context: Context) -> StatusEntry {
		Self.entry()
	}

	func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> ()) {
		completion(Self.entry())
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		let entry = Self.entry()

		// Theoretically. Practically, it will only get updated very rarely,
		// or from the app.
		let nextUpdate = entry.date.addingTimeInterval(2)

		let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
		completion(timeline)
	}

	private static func entry() -> StatusEntry {
		let icon: String
		var status: String
		var color: Color? = nil

		switch VpnManager.shared.status {
		case .connected:
			icon = Settings.onionOnly ? .imgOrbieOnionOnly : .imgOrbieOn

		case .evaluating, .connecting, .reasserting:
			icon = .imgOrbieStarting

		case .notInstalled:
			icon = .imgOrbieCharging

		case .invalid, .unknown:
			icon = .imgOrbieDead

		default:
			icon = .imgOrbieOff
		}

		if let error = VpnManager.shared.error {
			status = error.localizedDescription
			color = Color.red
		}
		else {
			status = VpnManager.shared.status.description
		}

		return StatusEntry(date: Date(), image: icon, status: status, color: color)
	}
}

struct StatusEntry: TimelineEntry {

	let date: Date

	let image: String
	let status: String
	let color: Color?
}

struct StatusWidgetEntryView : View {
	var entry: Provider.Entry

	@Environment(\.widgetFamily)
	var family: WidgetFamily

	var body: some View {
		ZStack {
			Color("WidgetBackground")
				.ignoresSafeArea()

			switch family {
			case .systemSmall: SmallView(entry: entry)
			default: MediumView(entry: entry)
			}
		}
		.widgetBackground(Color("WidgetBackground"))
	}
}

struct SmallView: View {
	var entry: Provider.Entry

	var body: some View {
		VStack {
			OrbieView(entry: entry)

			StatusView(entry: entry)
		}
	}
}

struct MediumView: View {
	var entry: Provider.Entry

	var body: some View {
		VStack {
			HStack {
				OrbieView(entry: entry)
				Link(destination: URL(string: "https://orbot.app/rc/start")!) {
					Button(NSLocalizedString("Start", comment: "")) {
						// Ignored
					}
					.foregroundColor(.white)
					.fontWeight(.semibold)
					.padding(EdgeInsets(top: 16, leading: 40, bottom: 16, trailing: 40))
					.background(Color("AccentColor"))
					.cornerRadius(8)
					.padding(.init(top: 0, leading: 8, bottom: 0, trailing: 24))
				}
			}

			StatusView(entry: entry)
		}
	}
}

struct OrbieView: View {
	var entry: Provider.Entry

	var body: some View {
		VStack {
			Image(entry.image)
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))

			Image("orbie.shadow")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(EdgeInsets(top: -4, leading: 34, bottom: 8, trailing: 34))
		}
	}
}

struct StatusView: View {
	var entry: Provider.Entry

	var body: some View {
		Text(entry.status)
			.foregroundColor(entry.color ?? .white)
			.fontWeight(.semibold)
			.padding(EdgeInsets(top: 0, leading: 8, bottom: 16, trailing: 8))
	}
}

struct OrbotWidget: Widget {
	let kind: String = "StatusWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			StatusWidgetEntryView(entry: entry)
		}
		.configurationDisplayName(String(format: NSLocalizedString("%@ Status", comment: "Placeholder is app name"), Bundle.app.displayName))
		.description(String(format: NSLocalizedString("Shows the connection status of %@.", comment: "Placeholder is app name"), Bundle.app.displayName))
		.supportedFamilies([.systemSmall])// TOOD:, .systemMedium])
	}
}

struct StatusWidget_Previews: PreviewProvider {
	static let entry = StatusEntry(date: Date(), image: .imgOrbieOff, status: "Ready to Connect", color: nil)

	static var previews: some View {
		StatusWidgetEntryView(entry: Self.entry)
			.previewContext(WidgetPreviewContext(family: .systemSmall))

		StatusWidgetEntryView(entry: Self.entry)
			.previewContext(WidgetPreviewContext(family: .systemMedium))
	}
}
