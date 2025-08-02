// PieChartView.swift (Report Extension target)
import SwiftUI

struct PieChartView: View {
    let configuration: String
    var body: some View {
        Text(configuration) // or your styled view
            .frame(height: 20)
    }
}

#Preview {
    PieChartView(configuration: "Hello, World!")
}
