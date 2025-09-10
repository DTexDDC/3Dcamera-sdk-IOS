import SwiftUI
import UIKit

struct TextView: UIViewRepresentable {
    @Binding var text: String  // Two way binding. Changes made to one change the other. So UIKit allows for user input text, when the user inputs the swift variable is changed.

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 20)
        textView.delegate = context.coordinator  // Allows for state changes to the SwiftUI, from the UIText. Coordinator delegates these changes.
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    // Coordinator giúp xử lý các sự kiện từ UIView
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView

        init(_ parent: TextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text  // Update the SwiftUI text when UITextView changes.
        }
    }
}
