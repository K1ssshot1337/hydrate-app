import SwiftUI
import HydrateKit

struct PortionPickerSheet: View {
    let container: DrinkContainer
    let onSelect: (Portion) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: container.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                    .padding(.top, 24)

                Text("\(container.name)")
                    .font(.title2)
                    .fontWeight(.bold)

                if let total = container.totalAmount {
                    Text("总容量 \(Int(total))ml")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if case .portionSelect(let portions) = container.mode {
                    VStack(spacing: 12) {
                        ForEach(portions) { portion in
                            Button {
                                onSelect(portion)
                            } label: {
                                HStack {
                                    Text(portion.name)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(Int(portion.amount))ml")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button("取消") {
                    dismiss()
                }
                .padding(.bottom)
            }
            .presentationDetents([.medium])
        }
    }
}
