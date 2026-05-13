import SwiftUI
import HydrateKit

struct SettingsView: View {
    @AppStorage("targetML") private var targetML: Double = 2000
    @AppStorage("startHour") private var startHour: Int = 9
    @AppStorage("startMinute") private var startMinute: Int = 0
    @AppStorage("endHour") private var endHour: Int = 21
    @AppStorage("endMinute") private var endMinute: Int = 0
    @AppStorage("baseIntervalMinutes") private var baseIntervalMinutes: Int = 45
    @AppStorage("weeklyReportEnabled") private var weeklyReportEnabled: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("每日饮水目标") {
                    HStack {
                        Text("\(Int(targetML)) ml")
                        Spacer()
                        Stepper("", value: $targetML, in: 1000...4000, step: 100)
                    }
                }

                Section("提醒时段") {
                    DatePicker("开始时间", selection: Binding(
                        get: { makeDate(hour: startHour, minute: startMinute) },
                        set: { date in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                            startHour = comps.hour ?? 9
                            startMinute = comps.minute ?? 0
                        }
                    ), displayedComponents: .hourAndMinute)

                    DatePicker("结束时间", selection: Binding(
                        get: { makeDate(hour: endHour, minute: endMinute) },
                        set: { date in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                            endHour = comps.hour ?? 21
                            endMinute = comps.minute ?? 0
                        }
                    ), displayedComponents: .hourAndMinute)

                    HStack {
                        Text("基础间隔")
                        Spacer()
                        Stepper("\(baseIntervalMinutes) 分钟", value: $baseIntervalMinutes, in: 15...120, step: 5)
                    }
                }

                Section("健康评估") {
                    Toggle("每周一推送评估报告", isOn: $weeklyReportEnabled)
                }

                Section("HealthKit") {
                    Button("请求 HealthKit 权限") {
                        Task {
                            try? await HealthKitService.shared.requestAuthorization()
                        }
                    }
                }

                Section("保存") {
                    Button("应用提醒设置") {
                        let rule = ReminderRule(
                            startHour: startHour,
                            startMinute: startMinute,
                            endHour: endHour,
                            endMinute: endMinute,
                            baseIntervalMinutes: baseIntervalMinutes,
                            enabledWeekdays: Set(1...7)
                        )
                        ReminderScheduler.shared.saveReminderRule(rule)
                        ReminderScheduler.shared.scheduleBackgroundRefresh()
                    }
                }
            }
            .navigationTitle("设置")
        }
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
}
