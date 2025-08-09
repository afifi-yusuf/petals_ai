//
//  DigitalHealthMonitorReport.swift
//  DigitalHealthMonitorReport
//
//  Created by Rishi Hundia on 02/08/2025.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct DigitalHealthMonitorReport: DeviceActivityReportExtension {
    @MainActor var body: some DeviceActivityReportScene {
        TotalActivityReport { TotalActivityView(totalActivity: $0) }
    }
}
