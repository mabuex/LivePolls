//
//  PollChart.swift
//  LivePolls
//
//  Created by Marcus Buexenstein on 2023/08/17.
//

import SwiftUI
import Charts

struct PollChart: View {
    let options: [Option]
    
    var body: some View {
        Chart {
            ForEach(options) { option in
                SectorMark(
                    angle: .value("Count", option.count),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Name", option.name))
            }
        }
    }
}

#Preview {
    PollChart(options: [
        .init(name: "PS5", count: 2),
        .init(name: "Xbox SX", count: 1),
        .init(name: "Switch", count: 2),
        .init(name: "PC", count: 1)
    ])
}
