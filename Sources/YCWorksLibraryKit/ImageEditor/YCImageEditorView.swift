import SwiftUI
@preconcurrency import UIKit

public struct YCImageEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let item: YCWorkItem
    private let onSave: (URL) async -> Void
    private let service = YCCoreImageEditingService()

    @State private var originalImage: UIImage?
    @State private var previewImage: UIImage?
    @State private var selectedTool: Tool = .adjust
    @State private var filter: YCImageFilter = .original
    @State private var filterIntensity: Double = 1
    @State private var adjustments = YCImageAdjustments.zero
    @State private var rotation: YCImageRotation = .degrees0
    @State private var isFlippedHorizontally = false
    @State private var cropAspect: YCImageCropAspect = .original
    @State private var isExporting = false
    @State private var errorMessage: String?

    public init(
        item: YCWorkItem,
        onSave: @escaping (URL) async -> Void
    ) {
        self.item = item
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    Color.black
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                    } else {
                        ProgressView()
                            .tint(.white)
                    }

                    if isExporting {
                        ProgressView(YCL10n.string("exporting"))
                            .padding(16)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                toolPanel
                    .background(.regularMaterial)
            }
            .navigationTitle(YCL10n.string("image_edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(YCL10n.string("cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(YCL10n.string("done")) {
                        Task { await export() }
                    }
                    .disabled(isExporting || originalImage == nil)
                }
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: filter) { _, _ in refreshPreview() }
        .onChange(of: filterIntensity) { _, _ in refreshPreview() }
        .onChange(of: adjustments) { _, _ in refreshPreview() }
        .onChange(of: rotation) { _, _ in refreshPreview() }
        .onChange(of: isFlippedHorizontally) { _, _ in refreshPreview() }
        .onChange(of: cropAspect) { _, _ in refreshPreview() }
        .alert(YCL10n.string("error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(YCL10n.string("ok"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var toolPanel: some View {
        VStack(spacing: 0) {
            switch selectedTool {
            case .adjust:
                YCImageAdjustmentPanel(adjustments: $adjustments)
            case .filter:
                YCImageFilterBar(selectedFilter: $filter, intensity: $filterIntensity)
            case .crop:
                YCImageCropView(selectedAspect: $cropAspect)
            case .rotate:
                rotatePanel
            }

            Divider()

            HStack {
                ForEach(Tool.allCases) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tool.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                            Text(tool.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(selectedTool == tool ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var rotatePanel: some View {
        HStack(spacing: 12) {
            Button {
                rotation = YCImageRotation(rawValue: (rotation.rawValue + 90) % 360) ?? .degrees0
            } label: {
                Label(YCL10n.string("rotate_90"), systemImage: "rotate.right")
            }
            .buttonStyle(.bordered)

            Button {
                isFlippedHorizontally.toggle()
            } label: {
                Label(YCL10n.string("flip_horizontal"), systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .frame(height: 92)
    }

    private func loadImage() async {
        let image = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: item.fileURL.path)
        }.value
        originalImage = image
        previewImage = image
        refreshPreview()
    }

    private func refreshPreview() {
        guard let originalImage else { return }
        let parameters = YCImageRenderParameters(
            filter: filter,
            filterIntensity: filterIntensity,
            adjustments: adjustments,
            rotation: rotation,
            isFlippedHorizontally: isFlippedHorizontally,
            cropAspect: cropAspect
        )
        Task {
            let rendered = await service.previewImage(from: originalImage, parameters: parameters, maxDimension: 1600)
            await MainActor.run {
                self.previewImage = rendered
            }
        }
    }

    private func export() async {
        isExporting = true
        defer { isExporting = false }

        let parameters = YCImageRenderParameters(
            filter: filter,
            filterIntensity: filterIntensity,
            adjustments: adjustments,
            rotation: rotation,
            isFlippedHorizontally: isFlippedHorizontally,
            cropAspect: cropAspect
        )

        do {
            let outputURL = try await service.renderEditedImage(imageURL: item.fileURL, parameters: parameters)
            await onSave(outputURL)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private enum Tool: String, CaseIterable, Identifiable {
        case adjust
        case filter
        case crop
        case rotate

        var id: String { rawValue }

        var title: String {
            switch self {
            case .adjust: return YCL10n.string("adjust")
            case .filter: return YCL10n.string("filters")
            case .crop: return YCL10n.string("crop")
            case .rotate: return YCL10n.string("rotate")
            }
        }

        var systemImage: String {
            switch self {
            case .adjust: return "slider.horizontal.3"
            case .filter: return "camera.filters"
            case .crop: return "crop"
            case .rotate: return "rotate.right"
            }
        }
    }
}
