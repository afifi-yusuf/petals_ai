// PieChartView.swift (Report Extension target)
import SwiftUI

struct PieChartView: View {
    let configuration: String

    var body: some View {
        ScrollView {
            Text(configuration)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body.monospacedDigit())
                .padding()
        }
    }
}
