import SwiftUI
import WidgetKit
import HydrateKit

struct WaterProgressEntry: TimelineEntry {
    let date: Date
    let currentML: Double
    let targetML: Double
}

struct WaterProgressProvider: TimelineProvider {
    private let store = WaterRecordStore()

    func placeholder(in context: Context) -> WaterProgressEntry {
        WaterProgressEntry(date: Date(), currentML: 1200, targetML: 2000)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterProgressEntry) -> Void) {
        let entry = WaterProgressEntry(
            date: Date(),
            currentML: store.todayTotal(),
            targetML: 2000
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterProgressEntry>) -> Void) {
        let entry = WaterProgressEntry(
            date: Date(),
            currentML: store.todayTotal(),
            targetML: 2000
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct WaterProgressRing: Widget {
    let kind = "WaterProgressRing"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProgressProvider()) { entry in
            WaterProgressEntryView(entry: entry)
                .containerBackground(.regularMaterial, for: .widget)
        }
        .configurationDisplayName("饮水进度")
        .description("显示今日饮水完成进度")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

struct WaterProgressEntryView: View {
    var entry: WaterProgressEntry

    var body: some View {
        let progress = entry.targetML > 0 ? min(entry.currentML / entry.targetML, 1.0) : 0

        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .medium))
        }
    }
}
