import SwiftUI
import HydrateKit
import Charts

struct HistoryView: View {
    private let store = WaterRecordStore()
    private let engine = AssessmentEngine()

    @State private var weeklyData: [(Date, Double)] = []
    @State private var monthlyData: [(week: String, avg: Double)] = []
    @State private var assessment: WeeklyAssessment?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let assessment = assessment {
                        assessmentCard(assessment)
                    }

                    weekChart
                    monthChart
                }
                .padding()
            }
            .navigationTitle("统计")
            .onAppear { loadData() }
        }
    }

    // MARK: - 评估卡片

    private func assessmentCard(_ a: WeeklyAssessment) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("本周评估")
                    .font(.headline)
                Spacer()
                Text(a.grade.rawValue)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(gradeColor(a.grade))
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Label("日均 \(Int(a.avgDailyML))ml", systemImage: "drop.fill")
                    Label("达标 \(a.goalMetDays)/7 天", systemImage: "checkmark.circle")
                }
                Spacer()
                Text(a.trend.rawValue)
                    .font(.system(size: 48))
            }

            Text(a.suggestion)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 本周柱状图

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本周饮水")
                .font(.headline)

            Chart {
                ForEach(weeklyData, id: \.0) { day, ml in
                    BarMark(
                        x: .value("日期", day, unit: .day),
                        y: .value("ml", ml)
                    )
                    .foregroundStyle(ml >= 2000 ? Color.blue : Color.blue.opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 180)
        }
    }

    // MARK: - 本月趋势

    private var monthChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本月趋势")
                .font(.headline)

            Chart {
                ForEach(monthlyData, id: \.week) { item in
                    LineMark(
                        x: .value("周", item.week),
                        y: .value("日均", item.avg)
                    )
                    .foregroundStyle(.cyan)
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: - 数据加载

    private func loadData() {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        weeklyData = (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let records = store.recordsForDate(date)
            let total = records.reduce(0) { $0 + $1.amount }
            return (date, total)
        }

        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        monthlyData = (0..<5).compactMap { weekIdx in
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: weekIdx, to: monthStart) else { return nil }
            let end = calendar.date(byAdding: .day, value: 7, to: weekDate)!
            let records = store.recordsBetween(start: weekDate, end: end)
            let avg = records.isEmpty ? 0 : records.reduce(0) { $0 + $1.amount } / 7.0
            return ("W\(weekIdx + 1)", avg)
        }

        let dailyAmounts = weeklyData.map { $0.1 }
        let prevWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
        let prevRecords = store.recordsBetween(start: prevWeekStart, end: weekStart)
        let prevAvg = prevRecords.isEmpty ? 0 : prevRecords.reduce(0) { $0 + $1.amount } / 7.0

        assessment = engine.assess(
            weekStart: weekStart,
            dailyAmounts: dailyAmounts,
            targetML: 2000,
            prevAvg: prevAvg
        )
    }

    private func gradeColor(_ grade: HydrateGrade) -> Color {
        switch grade {
        case .a: return .green
        case .b: return .blue
        case .c: return .orange
        case .d: return .red
        }
    }
}
