// PieChartReport.swift (Report Extension target)
import SwiftUI
import DeviceActivity
import ExtensionKit
import FamilyControls   // for ActivityCategory display names
import ManagedSettings

extension DeviceActivityReport.Context { static let pieChart = Self("Pie Chart") }

struct PieChartReport: DeviceActivityReportScene {
    // Define which context your scene will represent.
    let context: DeviceActivityReport.Context = .pieChart

    // Define the custom configuration and the resulting view for this report.
    let content: (String) -> PieChartView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> String {
        let fmt = DateComponentsFormatter()
        fmt.allowedUnits = [.hour, .minute]
        fmt.unitsStyle = .abbreviated
        fmt.zeroFormattingBehavior = .dropAll

        // Total screen time across the filter interval (your working pattern)
        let totalSeconds = await data
            .flatMap { $0.activitySegments }
            .reduce(0) { $0 + $1.totalActivityDuration }

        return "Total screen time: " + (fmt.string(from: totalSeconds) ?? "0m")
    }

}
