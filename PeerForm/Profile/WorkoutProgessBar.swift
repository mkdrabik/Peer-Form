//
//  WorkoutProgessBar.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/21/25.
//
import SwiftUI

struct WorkoutProgressBar: View {
    let completed: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(completed) / Double(total), 1.0)
    }
    
    private var percentageText: String {
        String(format: "%.0f%%", progress * 100)
    }

    private let barWidth: CGFloat = 160
    private let barHeight: CGFloat = 10

    var body: some View {
        HStack(spacing: 12) {
            
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(width: barWidth, height: barHeight)
                
                Capsule()
                    .fill(color(for: progress))
                    .frame(width: barWidth * progress, height: barHeight)
                    .animation(.easeOut(duration: 0.4), value: progress)
            }
            Text(percentageText)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
                .frame(width: 55, alignment: .leading)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
    }

    private func color(for progress: Double) -> Color {
        switch progress {
        case 0..<0.3: return .red
        default: return .green
        }
    }
}

#Preview{
    WorkoutProgressBar(completed: 4, total: 7)
}
