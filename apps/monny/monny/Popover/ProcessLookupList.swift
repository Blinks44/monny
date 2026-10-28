import AppKit
import SwiftUI

/// Results for a PID, port or local URL (Sketch frames `25`–`28`): who listens on the port and
/// which process has the PID, each expandable into details with actions for that PID only.
struct ProcessLookupList: View {
    let query: ProcessQuery
    let processes: [ProcessUsage]
    var refresh: () -> Void = { }
    /// Searches for another PID, such as the parent that started a process.
    var show: (pid_t) -> Void = { _ in }
    @State private var result: ProcessLookupResult?
    @State private var expanded: pid_t?
    @State private var ended: ProcessMatch?
    @State private var stillRunning: pid_t?
    @State private var endingPID: pid_t?
    @State private var confirmation: ProcessMatch?
    @State private var failure: ProcessActionFailure?
    @State private var terminator = ProcessTerminator()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let result {
                        if let ended { endedNote(ended, isOnlyContent: result.isEmpty) }
                        if result.isEmpty {
                            if ended == nil { emptyState }
                        } else {
                            sections(result)
                        }
                    } else {
                        Text("Searching…")
                            .font(Theme.body).foregroundStyle(Theme.textTertiary)
                            .frame(maxWidth: .infinity, minHeight: 360)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            Text("Shows your processes and the ports they listen on.")
                .font(Theme.footnote).foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.spaceM)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .card()
        .task(id: query) {
            result = nil
            ended = nil
            stillRunning = nil
            let found = await ProcessLookup.find(query)
            result = found
            // A single match is what the user is after, so its details open right away.
            let all = found.listeners + (found.process.map { [$0] } ?? [])
            expanded = all.count == 1 ? all.first?.id : nil
        }
        .alert(LocalizedStringResource("Force quit “\(confirmation?.name ?? "")”?"), item: $confirmation) { match in
            Button("Cancel", role: .cancel) { }
            Button("Force Quit", role: .destructive) { end(match, force: true) }
        } message: { match in
            Text("Only this process (PID \(String(match.id))) stops. Unsaved work in it will be lost.")
        }
        .alert(LocalizedStringResource("Couldn’t quit “\(failure?.name ?? "")”"), item: $failure) { _ in
            Button("OK", role: .cancel) { }
        } message: { failure in
            Text(failure.reason.message)
        }
    }

    @ViewBuilder private func sections(_ result: ProcessLookupResult) -> some View {
        if let port = query.port, !result.listeners.isEmpty {
            sectionTitle(Text("Listening on port \(String(port))"))
            ForEach(result.listeners) { match in row(match, port: port) }
            if ended?.ports.contains(where: { $0.port == port }) == true {
                Text("A new process is listening on port \(String(port)). Whatever started the old one may have started it again.")
                    .font(Theme.footnote).foregroundStyle(Theme.statusWarningText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, Theme.spaceM)
            }
        }
        if let process = result.process, let pid = query.pid {
            sectionTitle(Text("Process with PID \(String(pid))"))
            row(process, port: nil)
        }
    }

    private func sectionTitle(_ text: Text) -> some View {
        text.font(Theme.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            .padding(.top, 8).padding(.bottom, 2)
            .accessibilityAddTraits(.isHeader)
    }

    private func row(_ match: ProcessMatch, port: UInt16?) -> some View {
        let isExpanded = expanded == match.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                expanded = isExpanded ? nil : match.id
            } label: {
                HStack(spacing: Theme.spaceL) {
                    ProcessIcon(pid: match.id)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName(match)).font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary)
                        Text(subtitle(match)).font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                            .truncationMode(.middle)
                    }
                    .lineLimit(1)
                    Spacer(minLength: Theme.spaceM)
                    if let port {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(verbatim: ":\(port)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Theme.accentBrand)
                            Text(verbatim: "TCP").font(Theme.caption).foregroundStyle(Theme.textTertiary)
                        }
                    }
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 12)
                        .accessibilityHidden(true)
                }
                .frame(height: 47)
                .contentShape(.rect)
            }
            .buttonStyle(StaticButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityValue(Text(isExpanded ? "Expanded" : "Collapsed"))
            Theme.fillSeparator.frame(height: 1).padding(.leading, 42)
            if isExpanded { details(match) }
        }
    }

    private func details(_ match: ProcessMatch) -> some View {
        let usage = processes.first { $0.id == match.id && $0.startTime == match.startTime }
        return VStack(alignment: .leading, spacing: Theme.spaceL) {
            HStack(alignment: .top) {
                metric("CPU", color: Theme.metricCPU, value: usage?.cpu.formatted(.percent.precision(.fractionLength(1))))
                metric("Memory", color: Theme.metricMemory, value: usage?.memory.memoryText)
            }
            .padding(Theme.spaceL)
            .background(Theme.fillTrack, in: .rect(cornerRadius: Theme.radiusControl))

            if let executable = match.executable {
                VStack(alignment: .leading, spacing: 4) {
                    fieldLabel("Executable")
                    HStack {
                        Text(verbatim: executable)
                            .font(.system(size: 12, design: .monospaced)).foregroundStyle(Theme.textPrimary)
                            .lineLimit(1).truncationMode(.middle)
                            .textSelection(.enabled)
                        Spacer(minLength: Theme.spaceM)
                        Button("Copy Path", systemImage: "doc.on.doc") { copy(executable) }
                            .labelStyle(.iconOnly).buttonStyle(StaticButtonStyle())
                            .foregroundStyle(Theme.textSecondary)
                            .help(Text("Copy Path"))
                    }
                }
            }
            if let parent = match.parent {
                HStack(spacing: Theme.spaceL) {
                    fieldLabel("Started by")
                    Button {
                        show(parent.id)
                    } label: {
                        Label("\(parent.name) · PID \(String(parent.id))", systemImage: "chevron.right")
                            .labelStyle(TrailingIconLabelStyle())
                    }
                    .buttonStyle(PlainLinkButtonStyle())
                }
            }
            if !match.ports.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    fieldLabel("Local ports")
                    ForEach(match.ports, id: \.self) { listener in
                        HStack {
                            Text(verbatim: "\(listener.address):\(listener.port)")
                                .font(.system(size: 12, design: .monospaced)).foregroundStyle(Theme.textPrimary)
                            Spacer(minLength: Theme.spaceM)
                            Text(scope(of: listener)).font(Theme.caption).foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }
            if stillRunning == match.id {
                Text("“\(displayName(match))” is still running.")
                    .font(Theme.footnote).foregroundStyle(Theme.statusWarningText)
            }
            actions(match)
        }
        .padding(.vertical, Theme.spaceL)
    }

    @ViewBuilder private func actions(_ match: ProcessMatch) -> some View {
        HStack(spacing: Theme.spaceM) {
            if request(for: match) != nil {
                Button("Quit") { end(match, force: false) }
                    .buttonStyle(SecondaryButtonStyle())
                Button(LocalizedStringResource("process.forceQuit.menu", defaultValue: "Force Quit…")) { confirmation = match }
                    .buttonStyle(DestructiveButtonStyle())
            } else {
                Text("Monny cannot end this process.")
                    .font(Theme.footnote).foregroundStyle(Theme.textTertiary)
            }
            Spacer(minLength: 0)
            Menu {
                Button("Copy PID") { copy(String(match.id)) }
                if let executable = match.executable {
                    Button("Copy Path") { copy(executable) }
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(filePath: executable)])
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Theme.surfaceControl, in: .circle)
                    .controlElevation()
            }
            .menuStyle(.button)
            .buttonStyle(StaticButtonStyle())
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel(Text("More Actions"))
        }
        .disabled(endingPID != nil)
    }

    private func endedNote(_ match: ProcessMatch, isOnlyContent: Bool) -> some View {
        VStack(spacing: Theme.spaceM) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: isOnlyContent ? 28 : 15))
                .foregroundStyle(Theme.statusSuccessText)
                .accessibilityHidden(true)
            Text("“\(displayName(match))” has quit")
                .font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary)
            if isOnlyContent, let port = query.port, match.ports.contains(where: { $0.port == port }) {
                Text("None of your processes listens on port \(String(port)) now.")
                    .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: isOnlyContent ? 360 : nil)
        .padding(.vertical, isOnlyContent ? 0 : Theme.spaceM)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.spaceM) {
            switch query {
            case .port(let port):
                Text("Nothing is listening on port \(String(port))")
            case .number(let number) where query.port != nil:
                Text("No process with PID or port \(String(number))")
            default:
                Text("No process with PID \(String(query.pid ?? 0))")
            }
            Text("Monny checks processes running under your account.")
                .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
        }
        .font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private func metric(_ title: LocalizedStringKey, color: Color, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(Theme.footnote).foregroundStyle(color)
            if let value {
                Text(verbatim: value).font(Theme.headline).foregroundStyle(Theme.textPrimary).monospacedDigit()
            } else {
                UnavailableValue(font: Theme.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func fieldLabel(_ title: LocalizedStringKey) -> some View {
        Text(title).font(Theme.footnote).foregroundStyle(Theme.textSecondary)
    }

    private func displayName(_ match: ProcessMatch) -> String {
        NSRunningApplication(processIdentifier: match.id)?.localizedName ?? match.name
    }

    private func subtitle(_ match: ProcessMatch) -> String {
        let pid = "PID \(match.id)"
        guard let folder = match.folder else { return pid }
        return pid + " · " + (folder as NSString).abbreviatingWithTildeInPath
    }

    private func scope(of listener: PortListener) -> String {
        if listener.address == "*" { return String(localized: "TCP · All interfaces") }
        if listener.isLocalOnly { return String(localized: "TCP · This Mac only") }
        return "TCP"
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func request(for match: ProcessMatch) -> ProcessTerminationRequest? {
        let row = ProcessUsage(id: match.id, name: match.name, cpu: 0, memory: 0, power: 0, startTime: match.startTime)
        return ProcessTerminationRequest(row: row, processes: [])
    }

    /// A sent request is not proof of exit, so the result is reported only after the process is
    /// gone and the query has been read again.
    private func end(_ match: ProcessMatch, force: Bool) {
        guard endingPID == nil, let request = request(for: match) else { return }
        endingPID = match.id
        stillRunning = nil
        Task {
            defer { endingPID = nil }
            do {
                try await terminator.terminate(request, force: force)
            } catch {
                failure = ProcessActionFailure(name: displayName(match),
                                               reason: error as? ProcessTerminationFailure ?? .denied)
                refresh()
                result = await ProcessLookup.find(query)
                return
            }
            let exited = await ProcessLookup.waitForExit(match.id, startTime: match.startTime)
            refresh()
            let found = await ProcessLookup.find(query)
            if exited {
                ended = match
                expanded = nil
            } else {
                stillRunning = match.id
            }
            result = found
        }
    }
}

/// The app's icon, or a terminal tile for a process without an app, as in Sketch `Process/Port row`.
struct ProcessIcon: View {
    let pid: pid_t

    var body: some View {
        Group {
            if let icon = NSRunningApplication(processIdentifier: pid)?.icon {
                Image(nsImage: icon).resizable()
            } else {
                Text(verbatim: ">_")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.textOnAccent)
                    .frame(width: 30, height: 30)
                    .background(Theme.accentIconGraphite, in: .rect(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(width: 30, height: 30)
        .accessibilityHidden(true)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.font(.system(size: 9, weight: .bold))
        }
    }
}

/// Processes that have kept a core busy, above the list (Sketch frame `24`). Each row ends only
/// that process; clicking it searches for its PID to show the details.
struct NeedsAttentionCard: View {
    let items: [(process: ProcessUsage, duration: TimeInterval)]
    let isEnding: Bool
    let quit: (ProcessUsage) -> Void
    let forceQuit: (ProcessUsage) -> Void
    let show: (pid_t) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Needs attention")
                .font(Theme.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)
            ForEach(items.enumerated(), id: \.element.process.id) { index, item in
                if index > 0 { Theme.fillSeparator.frame(height: 1).padding(.leading, 42) }
                HStack(spacing: Theme.spaceL) {
                    Button {
                        show(item.process.id)
                    } label: {
                        HStack(spacing: Theme.spaceL) {
                            ProcessIcon(pid: item.process.id)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSRunningApplication(processIdentifier: item.process.id)?.localizedName ?? item.process.name)
                                    .font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary)
                                Text(detail(item))
                                    .font(Theme.footnote).foregroundStyle(Theme.statusWarningText)
                                    .monospacedDigit()
                            }
                            .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(StaticButtonStyle())
                    .accessibilityElement(children: .combine)
                    .accessibilityHint(Text("Shows details"))
                    Button("Quit") { quit(item.process) }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isEnding)
                }
                .frame(height: 47)
                .contextMenu {
                    Button("Quit") { quit(item.process) }.disabled(isEnding)
                    Button(LocalizedStringResource("process.forceQuit.menu", defaultValue: "Force Quit…")) { forceQuit(item.process) }
                        .disabled(isEnding)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .card()
    }

    private func detail(_ item: (process: ProcessUsage, duration: TimeInterval)) -> String {
        let cpu = item.process.cpu.formatted(.percent.precision(.fractionLength(0)))
        let duration = Duration.seconds(item.duration).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        return String(localized: "\(cpu) CPU for \(duration)")
    }
}
