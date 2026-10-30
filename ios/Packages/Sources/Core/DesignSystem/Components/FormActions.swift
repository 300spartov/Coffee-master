import SwiftUI

/// The bottom of a form: a primary Save button (spinner while saving) and, when editing, a
/// destructive action (Delete / Remove) that asks for confirmation first. Use it as the form's last section.
public struct FormActions: View {
    /// The destructive action and its confirmation, e.g. "Delete Bean" → "Delete this bean?" → "Delete".
    public struct Destructive {
        let title: String
        let confirmation: String
        let confirmTitle: String
        let action: () -> Void

        public init(_ title: String, confirmation: String, confirmTitle: String, action: @escaping () -> Void) {
            self.title = title
            self.confirmation = confirmation
            self.confirmTitle = confirmTitle
            self.action = action
        }
    }

    private let isSaving: Bool
    private let canSave: Bool
    private let identifier: String?
    private let save: () -> Void
    private let destructive: Destructive?
    @State private var isConfirming = false

    /// `identifier`: accessibility prefix, giving `<identifier>.save` and `<identifier>.delete`.
    public init(
        isSaving: Bool,
        canSave: Bool,
        identifier: String? = nil,
        destructive: Destructive? = nil,
        save: @escaping () -> Void
    ) {
        self.isSaving = isSaving
        self.canSave = canSave
        self.identifier = identifier
        self.destructive = destructive
        self.save = save
    }

    public var body: some View {
        Section {
            Button(action: save) {
                if isSaving { ProgressView() } else { Text(tr("Save")) }
            }
            .buttonStyle(.primary)
            .disabled(!canSave || isSaving)
            .accessibilityIdentifier(identifier.map { "\($0).save" } ?? "")
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            if let destructive {
                Button(destructive.title, role: .destructive) {
                    isConfirming = true
                }
                .foregroundStyle(.theme.error)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .accessibilityIdentifier(identifier.map { "\($0).delete" } ?? "")
                .confirmationDialog(destructive.confirmation, isPresented: $isConfirming, titleVisibility: .visible) {
                    Button(destructive.confirmTitle, role: .destructive, action: destructive.action)
                }
            }
        }
    }
}
