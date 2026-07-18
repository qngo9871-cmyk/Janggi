import SwiftUI

struct UpgradeView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss

    let feature: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Unlock Full Game")
                .font(.title2.bold())

            Text("\(feature) is available with the full version.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                Text("What you get:")
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text("Medium & Expert AI difficulty")
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text("Play vs Friend mode")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.15))
            )
            .padding(.horizontal, 32)

            Spacer()

            // Purchase section
            VStack(spacing: 12) {
                if let product = purchaseManager.product {
                    Button {
                        Task { await purchaseManager.purchase() }
                    } label: {
                        if purchaseManager.isPurchasing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Unlock Full Game — \(product.displayPrice)")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(purchaseManager.isPurchasing)
                } else if purchaseManager.productLoadFailed {
                    VStack(spacing: 8) {
                        Text("Unable to load purchase option.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Please check your connection and try again.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task { await purchaseManager.loadProduct() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ProgressView("Loading...")
                }

                Button {
                    Task { await purchaseManager.restorePurchases() }
                } label: {
                    Text("Restore Purchase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .disabled(purchaseManager.isPurchasing)

                if let error = purchaseManager.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .task {
            if purchaseManager.product == nil && !purchaseManager.isLoadingProduct {
                await purchaseManager.loadProduct()
            }
        }
        .onChange(of: purchaseManager.isPro) {
            if purchaseManager.isPro {
                dismiss()
            }
        }
    }
}
