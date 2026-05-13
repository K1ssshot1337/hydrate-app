import SwiftUI
import HydrateKit

struct PortionPickerView: View {
    let container: DrinkContainer
    let portions: [Portion]
    let onSelect: (Double) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(container.name) {
                ForEach(portions) { portion in
                    Button {
                        onSelect(portion.amount)
                        dismiss()
                    } label: {
                        HStack {
                            Text(portion.name)
                            Spacer()
                            Text("\(Int(portion.amount))ml")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
