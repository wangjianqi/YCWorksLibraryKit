import SwiftUI
import AVKit

public struct YCVideoEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let item: YCWorkItem
    private let onSave: (URL) async -> Void
    private let service = YCAVFoundationVideoEditingService()

    @State private var player: AVPlayer?
    @State private var selectedTool: Tool = .trim
    @State private var startTime: Double = 0
    @State private var endTime: Double = 1
    @State private var duration: Double = 1
    @State private var isMuted = false
    @State private var rotation: YCVideoRotation = .degrees0
    @State private var coverTime: Double = 0
    @State private var exportPreset: YCVideoExportPreset = .original
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
                    if let player {
                        VideoPlayer(player: player)
                            .onAppear { player.play() }
                            .onDisappear { player.pause() }
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
            .navigationTitle(YCL10n.string("video_edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(YCL10n.string("cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(YCL10n.string("export")) {
                        Task { await export() }
                    }
                    .disabled(isExporting)
                }
            }
        }
        .task {
            await loadMetadata()
            player = AVPlayer(url: item.fileURL)
        }
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
            case .trim:
                YCVideoTrimView(duration: duration, startTime: $startTime, endTime: $endTime)
            case .mute:
                mutePanel
            case .rotate:
                rotatePanel
            case .cover:
                YCVideoCoverPickerView(duration: duration, coverTime: $coverTime)
            case .export:
                exportPanel
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

    private var mutePanel: some View {
        Toggle(YCL10n.string("mute"), isOn: $isMuted)
            .padding()
            .frame(height: 92)
    }

    private var rotatePanel: some View {
        HStack(spacing: 12) {
            Button {
                rotation = YCVideoRotation(rawValue: (rotation.rawValue + 90) % 360) ?? .degrees0
            } label: {
                Label(YCL10n.string("rotate_90"), systemImage: "rotate.right")
            }
            .buttonStyle(.bordered)

            Text("\(rotation.rawValue)°")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .frame(height: 92)
    }

    private var exportPanel: some View {
        Picker(YCL10n.string("resolution"), selection: $exportPreset) {
            Text(YCL10n.string("original")).tag(YCVideoExportPreset.original)
            Text("1080p").tag(YCVideoExportPreset.hd1080)
            Text("720p").tag(YCVideoExportPreset.hd720)
        }
        .pickerStyle(.segmented)
        .padding()
        .frame(height: 92)
    }

    private func loadMetadata() async {
        let asset = AVURLAsset(url: item.fileURL)
        let seconds = (try? await asset.load(.duration).seconds) ?? item.duration ?? 1
        duration = max(seconds, 1)
        startTime = 0
        endTime = duration
        coverTime = duration / 2
    }

    private func export() async {
        isExporting = true
        defer { isExporting = false }

        do {
            var currentURL = item.fileURL
            if startTime > 0.01 || endTime < duration - 0.01 {
                currentURL = try await service.trim(videoURL: currentURL, startTime: startTime, endTime: endTime)
            }
            if isMuted {
                currentURL = try await service.mute(videoURL: currentURL)
            }
            if rotation != .degrees0 {
                currentURL = try await service.rotate(videoURL: currentURL, rotation: rotation)
            }
            let config = YCVideoExportConfiguration(preset: exportPreset, keepsAudio: !isMuted, outputFileType: .mp4)
            currentURL = try await service.export(videoURL: currentURL, configuration: config)
            _ = try? await service.generateThumbnail(videoURL: currentURL, at: coverTime)
            await onSave(currentURL)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private enum Tool: String, CaseIterable, Identifiable {
        case trim
        case mute
        case rotate
        case cover
        case export

        var id: String { rawValue }

        var title: String {
            switch self {
            case .trim: return YCL10n.string("trim")
            case .mute: return YCL10n.string("mute")
            case .rotate: return YCL10n.string("rotate")
            case .cover: return YCL10n.string("cover")
            case .export: return YCL10n.string("export")
            }
        }

        var systemImage: String {
            switch self {
            case .trim: return "timeline.selection"
            case .mute: return "speaker.slash"
            case .rotate: return "rotate.right"
            case .cover: return "photo"
            case .export: return "square.and.arrow.up"
            }
        }
    }
}
