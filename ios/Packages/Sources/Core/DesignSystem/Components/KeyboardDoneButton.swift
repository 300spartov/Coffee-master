import SwiftUI
import UIKit

public extension View {
    /// Done above the keyboard, so it can always be closed by hand (number pads have no return key).
    /// Applied once at each screen's root (`LocalizedRoot`); it covers every field on the screen.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(tr("Done")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.semibold)
                .accessibilityIdentifier("keyboard.done")
            }
        }
    }
}
