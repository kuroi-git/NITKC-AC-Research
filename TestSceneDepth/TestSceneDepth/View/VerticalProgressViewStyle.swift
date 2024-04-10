import SwiftUI

// 累積危険値をグラフ化したかった、くっそ重くなって断念
// 消しても多分問題ない

struct VerticalProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 45.0)
                        .frame(width: 30, height: geometry.size.height)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)

                    RoundedRectangle(cornerRadius: 45.0)
                        .frame(width: 30, height: CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.height)
                        .foregroundColor(Color.blue)
                        .offset(y: (1 - CGFloat(configuration.fractionCompleted ?? 0)) * geometry.size.height)
                        .animation(.easeInOut, value: configuration.fractionCompleted)
                }
            }
        }
    }
}
