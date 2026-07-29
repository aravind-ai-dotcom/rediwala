import AVKit
import SwiftUI

struct AudioRoutePickerButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        view.tintColor = UIColor(AppTheme.primary)
        view.activeTintColor = UIColor(AppTheme.accent)
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
