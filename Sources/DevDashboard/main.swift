import SwiftUI
import AppKit
import ServiceManagement

@main
struct MenuBarOrgApp: App {
    @StateObject private var systemMonitor = SystemMonitor()
    @StateObject private var cliToolsMonitor = CLIToolsMonitor()
    @StateObject private var sharedState = SharedState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra(getMenubarTitle()) {
            MenuBarView()
                .environmentObject(systemMonitor)
                .environmentObject(cliToolsMonitor)
                .environmentObject(sharedState)
        }
        .menuBarExtraStyle(.window)
    }
    
    private func getMenubarTitle() -> String {
        switch sharedState.menubarTitleMode {
        case .isp:
            return systemMonitor.shortOrg.isEmpty ? "Loading..." : systemMonitor.shortOrg
        case .audioDevice:
            return systemMonitor.audioDevice.isEmpty ? "Loading..." : systemMonitor.audioDevice
        case .currentlyPlaying:
            let playing = systemMonitor.currentlyPlaying
            return playing == "No music playing" || playing.isEmpty ? "♪ No Music" : "♪ \(playing)"
        }
    }

    init() {
        let sysMonitor = SystemMonitor()
        let cliMonitor = CLIToolsMonitor()
        let state = SharedState()
        
        _systemMonitor = StateObject(wrappedValue: sysMonitor)
        _cliToolsMonitor = StateObject(wrappedValue: cliMonitor)
        _sharedState = StateObject(wrappedValue: state)
        
        sysMonitor.startMonitoring()
        // Start fetching CLI data immediately
        cliMonitor.fetchAllData()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
    }
}

struct MenuBarView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @EnvironmentObject var cliToolsMonitor: CLIToolsMonitor
    @EnvironmentObject var sharedState: SharedState
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("System").tag(0)
                Text("CLI Tools").tag(1)
                Text("Settings").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 8)

            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    SystemView()
                case 1:
                    CLIToolsView()
                case 2:
                    SettingsView()
                default:
                    SystemView()
                }
            }
        }
        .frame(width: 400, height: 450)
        .onAppear { 
            if #available(macOS 13.0, *) {
                sharedState.launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }
}

struct SystemView: View {
    @EnvironmentObject var systemMonitor: SystemMonitor
    @EnvironmentObject var sharedState: SharedState

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // IP Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                            Text("Network Info")
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            dataRow(label: "ISP", value: systemMonitor.currentOrg)
                            dataRow(label: "IP", value: systemMonitor.currentIP)
                            dataRow(label: "Location", value: "\(systemMonitor.city), \(systemMonitor.country)")
                        }
                    }
                    
                    // System Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.green)
                            Text("System Resources")
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            dataRow(label: "CPU Usage", value: systemMonitor.cpuUsage.isEmpty ? "Loading..." : systemMonitor.cpuUsage)
                            dataRow(label: "Memory", value: systemMonitor.memoryUsage.isEmpty ? "Loading..." : systemMonitor.memoryUsage)
                            dataRow(label: "Disk Space", value: systemMonitor.diskUsage.isEmpty ? "Loading..." : systemMonitor.diskUsage)
                        }
                    }
                    
                    // Audio Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speaker.wave.3")
                                .foregroundColor(.purple)
                            Text("Audio Info")
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            dataRow(label: "Output Device", value: systemMonitor.audioDevice.isEmpty ? "Loading..." : systemMonitor.audioDevice)
                            dataRow(label: "Currently Playing", value: systemMonitor.currentlyPlaying.isEmpty ? "Loading..." : systemMonitor.currentlyPlaying)
                        }
                    }
                    
                    // Last Updated
                    VStack(alignment: .leading, spacing: 4) {
                        dataRow(label: "Updated", value: systemMonitor.lastUpdated)
                    }
                }
                .padding()
            }

            if sharedState.showCopiedMessage {
                Text("Copied to clipboard!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            Divider()

            HStack {
                Button("Refresh Now") {
                    systemMonitor.fetchIPInfo()
                    systemMonitor.fetchSystemInfo()
                    systemMonitor.fetchMusicInfo()
                }
                .keyboardShortcut(.init("r"), modifiers: [])

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func dataRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            sharedState.copyToClipboard(value)
        }
        .help("Click to copy \(value)")
    }
}

struct CLIToolsView: View {
    @EnvironmentObject var cliToolsMonitor: CLIToolsMonitor
    @EnvironmentObject var sharedState: SharedState
    @State private var selectedTool = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tool selector
            Picker("", selection: $selectedTool) {
                Text("kubectl").tag(0)
                Text("Azure").tag(1)
                Text("GitHub").tag(2)
                Text("Pulumi").tag(3)
                Text("Docker").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch selectedTool {
                    case 0:
                        kubectlSection()
                    case 1:
                        azureSection()
                    case 2:
                        githubSection()
                    case 3:
                        pulumiSection()
                    case 4:
                        dockerSection()
                    default:
                        kubectlSection()
                    }
                }
                .padding()
            }

            if sharedState.showCopiedMessage {
                Text("Copied to clipboard!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            Divider()

            HStack {
                Button("Refresh All") {
                    cliToolsMonitor.fetchAllData()
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func kubectlSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "helm")
                    .foregroundColor(.blue)
                Text("Kubernetes (kubectl)")
                    .font(.headline)
            }

            if let error = cliToolsMonitor.errors["kubectl"] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text("Current Context:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(cliToolsMonitor.kubectlContext)
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                            .textSelection(.enabled)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sharedState.copyToClipboard(cliToolsMonitor.kubectlContext)
                    }
                    .help("Click to copy \(cliToolsMonitor.kubectlContext)")

                    if !cliToolsMonitor.kubectlContexts.isEmpty {
                        Text("Available Contexts:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)

                        VStack(spacing: 2) {
                            ForEach(cliToolsMonitor.kubectlContexts, id: \.self) { context in
                                contextButton(context: context, isCurrent: context == cliToolsMonitor.kubectlContext)
                            }
                        }
                    }
                }
            }

            Text("Updated: \(cliToolsMonitor.lastUpdated)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func azureSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cloud")
                    .foregroundColor(.blue)
                Text("Azure CLI")
                    .font(.headline)
            }

            if let error = cliToolsMonitor.errors["azure"] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    dataRow(label: "Current Subscription", value: cliToolsMonitor.azureSubscription)

                    if !cliToolsMonitor.azureSubscriptions.isEmpty {
                        Text("Available Subscriptions:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)

                        VStack(spacing: 2) {
                            ForEach(cliToolsMonitor.azureSubscriptions, id: \.id) { subscription in
                                subscriptionButton(subscription: subscription, isCurrent: subscription.name == cliToolsMonitor.azureSubscription)
                            }
                        }
                    }
                }
            }

            Text("Updated: \(cliToolsMonitor.lastUpdated)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func githubSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                Text("GitHub CLI")
                    .font(.headline)
            }

            if let error = cliToolsMonitor.errors["github"] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    dataRow(label: "Username", value: cliToolsMonitor.githubUser)
                    if !cliToolsMonitor.githubName.isEmpty {
                        dataRow(label: "Name", value: cliToolsMonitor.githubName)
                    }
                    if !cliToolsMonitor.githubCompany.isEmpty {
                        dataRow(label: "Company", value: cliToolsMonitor.githubCompany)
                    }
                    if !cliToolsMonitor.githubLocation.isEmpty {
                        dataRow(label: "Location", value: cliToolsMonitor.githubLocation)
                    }

                    if !cliToolsMonitor.githubPRs.isEmpty {
                        Text("Your Pull Requests:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)

                        VStack(spacing: 2) {
                            ForEach(cliToolsMonitor.githubPRs, id: \.title) { pr in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(pr.title)
                                            .font(.caption)
                                            .lineLimit(2)
                                        Text(pr.repo)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    sharedState.copyToClipboard(pr.title)
                                }
                            }
                        }
                    }
                }
            }

            Text("Updated: \(cliToolsMonitor.lastUpdated)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func pulumiSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.columns")
                    .foregroundColor(.blue)
                Text("Pulumi")
                    .font(.headline)
            }

            if let error = cliToolsMonitor.errors["pulumi"] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    dataRow(label: "User", value: cliToolsMonitor.pulumiUser)
                    if !cliToolsMonitor.pulumiURL.isEmpty {
                        dataRow(label: "URL", value: cliToolsMonitor.pulumiURL)
                    }
                    
                    if !cliToolsMonitor.pulumiOrgs.isEmpty {
                        Text("Organizations:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(cliToolsMonitor.pulumiOrgs, id: \.self) { org in
                                HStack {
                                    Text("• \(org)")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    sharedState.copyToClipboard(org)
                                }
                            }
                        }
                    }


                }
            }

            Text("Updated: \(cliToolsMonitor.lastUpdated)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func dockerSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shippingbox")
                    .foregroundColor(.blue)
                Text("Docker")
                    .font(.headline)
            }

            // Docker Engine Status
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: cliToolsMonitor.dockerEngineRunning ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(cliToolsMonitor.dockerEngineRunning ? .green : .red)
                        .font(.caption)
                    
                    Text("Docker Engine")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(cliToolsMonitor.dockerEngineRunning ? "Running" : "Stopped")
                        .font(.caption)
                        .foregroundColor(cliToolsMonitor.dockerEngineRunning ? .green : .red)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { cliToolsMonitor.dockerEngineRunning },
                        set: { _ in cliToolsMonitor.toggleDockerEngine() }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .scaleEffect(0.8)
                    .disabled(cliToolsMonitor.errors["docker"] == "Docker not installed")
                }
            }

            if let error = cliToolsMonitor.errors["docker"] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if cliToolsMonitor.dockerEngineRunning {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    let runningCount = cliToolsMonitor.dockerContainers.filter { $0.status.contains("Up") }.count
                    Text("Containers (\(runningCount)/\(cliToolsMonitor.dockerContainers.count) running):")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if cliToolsMonitor.dockerContainers.isEmpty {
                        Text("No containers found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: 6) {
                            ForEach(cliToolsMonitor.dockerContainers, id: \.name) { container in
                                containerRow(container: container)
                            }
                        }
                    }
                }
            } else {
                Text("Start Docker Engine to manage containers")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            Text("Updated: \(cliToolsMonitor.lastUpdated)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func containerRow(container: (name: String, image: String, status: String)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: container.status.contains("Up") ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(container.status.contains("Up") ? .green : .red)
                    .font(.caption)
                
                Text(container.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { container.status.contains("Up") },
                    set: { _ in
                        cliToolsMonitor.toggleDockerContainer(container.name, isRunning: container.status.contains("Up"))
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(0.8)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                sharedState.copyToClipboard(container.name)
            }
            
            HStack {
                Text("Image:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(container.image)
                    .font(.caption2)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.leading, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                sharedState.copyToClipboard(container.image)
            }
            
            HStack {
                Text("Status:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(container.status)
                    .font(.caption2)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.leading, 16)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)
    }

    @ViewBuilder
    private func contextButton(context: String, isCurrent: Bool) -> some View {
        Button(action: {
            cliToolsMonitor.switchKubectlContext(to: context)
        }) {
            HStack {
                Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCurrent ? .green : .secondary)
                Text(context)
                    .font(.caption)
                    .foregroundColor(isCurrent ? .primary : .secondary)
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func subscriptionButton(subscription: (name: String, id: String), isCurrent: Bool) -> some View {
        VStack(spacing: 4) {
            Button(action: {
                cliToolsMonitor.switchAzureSubscription(to: subscription.id)
            }) {
                HStack {
                    Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCurrent ? .green : .secondary)
                    Text(subscription.name)
                        .font(.caption)
                        .foregroundColor(isCurrent ? .primary : .secondary)
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack {
                Text(subscription.id)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .textSelection(.enabled)
                Spacer()
                Button(action: {
                    sharedState.copyToClipboard(subscription.id)
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Copy subscription ID")
            }
            .padding(.leading, 20)
        }
        .padding(.vertical, 2)
    }



    @ViewBuilder
    private func dataRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            sharedState.copyToClipboard(value)
        }
        .help("Click to copy \(value)")
    }
}

struct KubernetesView: View {
    @EnvironmentObject var kubectlMonitor: KubectlMonitor
    @EnvironmentObject var sharedState: SharedState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "helm")
                    .foregroundColor(.blue)
                Text("Kubernetes")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("Current Context:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(kubectlMonitor.currentContext)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    sharedState.copyToClipboard(kubectlMonitor.currentContext)
                }

                Text("Switch Context:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(kubectlMonitor.availableContexts, id: \.self) { context in
                            HStack {
                                Button(action: {
                                    kubectlMonitor.switchContext(to: context)
                                }) {
                                    HStack {
                                        Image(systemName: kubectlMonitor.currentContext == context ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(kubectlMonitor.currentContext == context ? .green : .secondary)
                                        Text(context)
                                            .font(.caption)
                                            .foregroundColor(kubectlMonitor.currentContext == context ? .primary : .secondary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .frame(maxHeight: 100)

                if let error = kubectlMonitor.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Text("Updated: \(kubectlMonitor.lastUpdated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if sharedState.showCopiedMessage {
                Text("Copied to clipboard!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            Divider()

            HStack {
                Button("Refresh") {
                    kubectlMonitor.fetchContexts()
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
    }
}

struct PulumiView: View {
    @EnvironmentObject var pulumiMonitor: PulumiMonitor
    @EnvironmentObject var sharedState: SharedState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cube.box")
                    .foregroundColor(.purple)
                Text("Pulumi")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("Current Stack:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(pulumiMonitor.currentStack)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    sharedState.copyToClipboard(pulumiMonitor.currentStack)
                }

                if !pulumiMonitor.availableStacks.isEmpty {
                    Text("Available Stacks:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(pulumiMonitor.availableStacks, id: \.self) { stack in
                                Button(action: {
                                    pulumiMonitor.selectStack(stack)
                                }) {
                                    HStack {
                                        Image(systemName: pulumiMonitor.currentStack == stack ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(pulumiMonitor.currentStack == stack ? .green : .secondary)
                                        Text(stack)
                                            .font(.caption)
                                            .foregroundColor(pulumiMonitor.currentStack == stack ? .primary : .secondary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .frame(maxHeight: 80)
                }

                if let error = pulumiMonitor.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Text("Updated: \(pulumiMonitor.lastUpdated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if sharedState.showCopiedMessage {
                Text("Copied to clipboard!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            Divider()

            HStack {
                Button("Refresh") {
                    pulumiMonitor.fetchStacks()
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
    }
}

struct GitHubView: View {
    @EnvironmentObject var githubMonitor: GitHubMonitor
    @EnvironmentObject var sharedState: SharedState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.black)
                Text("GitHub")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("User:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(githubMonitor.currentUser)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    sharedState.copyToClipboard(githubMonitor.currentUser)
                }

                Text("Open PRs (\(githubMonitor.openPRs.count)):")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                if !githubMonitor.openPRs.isEmpty {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(githubMonitor.openPRs) { pr in
                                HStack {
                                    Text("#\(pr.number)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .frame(width: 30, alignment: .leading)
                                    Text(pr.title)
                                        .font(.caption)
                                        .lineLimit(2)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    sharedState.copyToClipboard(pr.url)
                                }
                                .padding(.vertical, 1)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                } else {
                    Text("No open PRs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let error = githubMonitor.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Text("Updated: \(githubMonitor.lastUpdated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if sharedState.showCopiedMessage {
                Text("Copied to clipboard!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            Divider()

            HStack {
                Button("Refresh") {
                    githubMonitor.fetchStatus()
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
    }
}

struct AzureView: View {
    @EnvironmentObject var azureMonitor: AzureMonitor
    @EnvironmentObject var sharedState: SharedState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cloud")
                    .foregroundColor(.blue)
                Text("Azure")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("Current Subscription:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(azureMonitor.currentSubscription)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    sharedState.copyToClipboard(azureMonitor.currentSubscription)
                }

                Text("Switch Subscription:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(azureMonitor.availableSubscriptions) { subscription in
                            Button(action: {
                                azureMonitor.selectSubscription(subscription)
                            }) {
                                HStack {
                                    Image(systemName: subscription.isDefault ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(subscription.isDefault ? .green : .secondary)
                                    VStack(alignment: .leading) {
                                        Text(subscription.name)
                                            .font(.caption)
                                            .foregroundColor(subscription.isDefault ? .primary : .secondary)
                                            .lineLimit(1)
                                        Text(subscription.id)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                // Double-tap to copy subscription ID
                                sharedState.copyToClipboard(subscription.id)
                            }
                        }
                    }
                }
                .frame(maxHeight: 120)

                if let error = azureMonitor.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Text("Updated: \(azureMonitor.lastUpdated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if sharedState.showCopiedMessage {
                Text("Copied to clipboard!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            Divider()

            HStack {
                Button("Refresh") {
                    azureMonitor.fetchSubscriptions()
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
    }
}

struct SettingsView: View {
    @EnvironmentObject var sharedState: SharedState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape")
                    .foregroundColor(.blue)
                Text("Settings")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Menubar Title Display")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(MenubarTitleMode.allCases, id: \.self) { mode in
                        HStack {
                            Button(action: {
                                sharedState.menubarTitleMode = mode
                            }) {
                                HStack {
                                    Image(systemName: sharedState.menubarTitleMode == mode ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(sharedState.menubarTitleMode == mode ? .accentColor : .secondary)
                                    Text(mode.displayName)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    }
                }
            }

            Divider()

            Toggle("Launch at Login", isOn: $sharedState.launchAtLogin)
                .onChange(of: sharedState.launchAtLogin) { newValue in
                    sharedState.setLaunchAtLogin(enabled: newValue)
                }

            Spacer()

            Divider()

            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
    }
}

enum MenubarTitleMode: String, CaseIterable {
    case isp = "ISP Name"
    case audioDevice = "Audio Device"
    case currentlyPlaying = "Currently Playing"
    
    var displayName: String {
        switch self {
        case .isp:
            return "ISP Name"
        case .audioDevice:
            return "Audio Device"
        case .currentlyPlaying:
            return "Currently Playing"
        }
    }
}

final class SharedState: ObservableObject, @unchecked Sendable {
    @Published var showCopiedMessage = false
    @Published var launchAtLogin = false
    @Published var menubarTitleMode: MenubarTitleMode = .isp
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        showCopiedMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showCopiedMessage = false
        }
    }
    
    func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                launchAtLogin = enabled
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
                launchAtLogin = !enabled
            }
        }
    }
}

final class CLIToolsMonitor: ObservableObject, @unchecked Sendable {
    @Published var kubectlContext: String = "Loading..."
    @Published var kubectlContexts: [String] = []
    @Published var azureSubscription: String = "Loading..."
    @Published var azureSubscriptions: [(name: String, id: String)] = []
    @Published var githubUser: String = "Loading..."
    @Published var githubName: String = ""
    @Published var githubCompany: String = ""
    @Published var githubLocation: String = ""
    @Published var githubPRs: [(title: String, repo: String)] = []
    @Published var pulumiUser: String = "Loading..."
    @Published var pulumiOrgs: [String] = []
    @Published var pulumiURL: String = ""
    @Published var dockerContainers: [(name: String, image: String, status: String)] = []
    @Published var dockerEngineRunning: Bool = false
    @Published var lastUpdated: String = "Never"
    @Published var errors: [String: String] = [:]
    
    func fetchAllData() {
        Task {
            await fetchKubectl()
            await fetchAzure()
            await fetchGitHub()
            await fetchPulumi()
            await fetchDocker()
            
            await MainActor.run {
                self.updateTimestamp()
            }
        }
    }
    
    private func fetchKubectl() async {
        let contexts = await executeCommand("kubectl config get-contexts -o name")
        let current = await executeCommand("kubectl config current-context")
        
        await MainActor.run {
            if contexts.contains("command not found") || contexts.contains("Error") {
                self.errors["kubectl"] = "kubectl not found"
                self.kubectlContext = "Not available"
                self.kubectlContexts = []
            } else {
                // Normalization helper trims whitespace + newlines + stray asterisks (shouldn't appear with -o name, but defensive)
                func normalize(_ s: String) -> String {
                    s.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "*", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }

                // Clean and filter contexts
                var cleaned = contexts.components(separatedBy: .newlines)
                    .map { normalize($0) }
                    .filter { !$0.isEmpty }

                // Clean current context
                let cleanCurrent = normalize(current)

                // If for some reason current context isn't in the list (race condition / kube mis-config), add it to top
                if !cleanCurrent.isEmpty, !cleaned.contains(cleanCurrent) {
                    cleaned.insert(cleanCurrent, at: 0)
                }

                self.kubectlContexts = cleaned
                self.kubectlContext = cleanCurrent.isEmpty ? "Unknown" : cleanCurrent
                self.errors["kubectl"] = nil
            }
        }
    }
    
    private func fetchAzure() async {
        let result = await executeCommand("az account list --output json")
        
        await MainActor.run {
            if result.contains("command not found") || result.contains("Error") || result.contains("Please run 'az login'") {
                self.errors["azure"] = "Azure CLI not found or not logged in"
                self.azureSubscription = "Not available"
            } else {
                parseAzureSubscriptions(result)
            }
        }
    }
    
    private func fetchGitHub() async {
        let userInfo = await executeCommand("gh api user --jq '{login: .login, name: .name, company: .company, location: .location}'")
        let prs = await executeCommand("gh pr list --author @me --json title,repository --limit 10")
        
        await MainActor.run {
            if userInfo.contains("command not found") || userInfo.contains("Error") || userInfo.isEmpty {
                self.errors["github"] = "GitHub CLI not found or not logged in"
                self.githubUser = "Not available"
            } else {
                parseGitHubUser(userInfo)
                parseGitHubPRs(prs)
                self.errors["github"] = nil
            }
        }
    }
    
    private func fetchPulumi() async {
        let whoami = await executeCommand("pulumi whoami -v -j")
        
        await MainActor.run {
            if whoami.contains("command not found") || whoami.contains("Error") {
                self.errors["pulumi"] = "Pulumi not found or not logged in"
                self.pulumiUser = "Not available"
            } else {
                parsePulumiUser(whoami)
                self.errors["pulumi"] = nil
            }
        }
    }
    
    private func fetchDocker() async {
        // Check Docker engine status first
        let engineStatus = await executeCommand("docker info --format '{{.ServerVersion}}'")
        let containers = await executeCommand("docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}'")
        
        await MainActor.run {
            if engineStatus.contains("command not found") {
                self.errors["docker"] = "Docker not installed"
                self.dockerEngineRunning = false
                self.dockerContainers = []
            } else if engineStatus.contains("Cannot connect to the Docker daemon") || engineStatus.contains("Error") {
                self.dockerEngineRunning = false
                self.dockerContainers = []
                self.errors["docker"] = nil // Clear error since Docker is installed but engine is stopped
            } else {
                self.dockerEngineRunning = true
                parseDockerContainers(containers)
                self.errors["docker"] = nil
            }
        }
    }
    
    func switchKubectlContext(to context: String) {
        Task {
            let result = await executeCommand("kubectl config use-context \(context)")
            await MainActor.run {
                if result.isEmpty || !result.contains("error") {
                    self.kubectlContext = context
                } else {
                    self.errors["kubectl"] = "Failed to switch context"
                }
                self.updateTimestamp()
            }
        }
    }
    
    func switchAzureSubscription(to subscriptionId: String) {
        Task {
            let result = await executeCommand("az account set --subscription \(subscriptionId)")
            if result.isEmpty || !result.contains("error") {
                await fetchAzure()
            } else {
                await MainActor.run {
                    self.errors["azure"] = "Failed to switch subscription"
                }
            }
        }
    }
    
    func refreshPulumi() {
        Task {
            await fetchPulumi()
            await MainActor.run {
                self.updateTimestamp()
            }
        }
    }
    
    private func parseAzureSubscriptions(_ json: String) {
        guard let data = json.data(using: .utf8) else { return }
        
        do {
            if let subscriptions = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var subs: [(name: String, id: String)] = []
                var current = "Not found"
                
                for sub in subscriptions {
                    if let name = sub["name"] as? String,
                       let id = sub["id"] as? String {
                        subs.append((name: name, id: id))
                        
                        if let isDefault = sub["isDefault"] as? Bool, isDefault {
                            current = name
                        }
                    }
                }
                
                self.azureSubscriptions = subs
                self.azureSubscription = current
                self.errors["azure"] = nil
            }
        } catch {
            self.errors["azure"] = "Failed to parse subscriptions"
        }
    }
    
    private func parseGitHubPRs(_ json: String) {
        guard let data = json.data(using: .utf8) else { return }
        
        do {
            if let prs = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var results: [(title: String, repo: String)] = []
                
                for pr in prs {
                    if let title = pr["title"] as? String,
                       let repository = pr["repository"] as? [String: Any],
                       let repoName = repository["name"] as? String {
                        results.append((title: title, repo: repoName))
                    }
                }
                
                self.githubPRs = results
            }
        } catch {
            // Ignore parsing errors for PRs
        }
    }
    
    private func parsePulumiUser(_ json: String) {
        guard let data = json.data(using: .utf8) else { return }
        
        do {
            if let userInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.pulumiUser = userInfo["user"] as? String ?? "Unknown"
                self.pulumiOrgs = userInfo["organizations"] as? [String] ?? []
                self.pulumiURL = userInfo["url"] as? String ?? ""
            }
        } catch {
            self.pulumiUser = "Parse error"
        }
    }
    
    private func parseGitHubUser(_ json: String) {
        guard let data = json.data(using: .utf8) else { return }
        
        do {
            if let userInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.githubUser = userInfo["login"] as? String ?? "Unknown"
                self.githubName = userInfo["name"] as? String ?? ""
                self.githubCompany = userInfo["company"] as? String ?? ""
                self.githubLocation = userInfo["location"] as? String ?? ""
            }
        } catch {
            self.githubUser = "Parse error"
        }
    }
    
    private func parseDockerContainers(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        var containers: [(name: String, image: String, status: String)] = []
        
        // Process all non-empty lines (no header with this format)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                let parts = trimmed.components(separatedBy: "\t")
                if parts.count >= 3 {
                    let name = parts[0].trimmingCharacters(in: .whitespaces)
                    let image = parts[1].trimmingCharacters(in: .whitespaces)
                    let status = parts[2].trimmingCharacters(in: .whitespaces)
                    containers.append((name: name, image: image, status: status))
                }
            }
        }
        
        self.dockerContainers = containers
    }
    
    func toggleDockerContainer(_ containerName: String, isRunning: Bool) {
        Task {
            let command = isRunning ? "docker stop \(containerName)" : "docker start \(containerName)"
            let result = await executeCommand(command)
            
            await MainActor.run {
                if result.contains("Error") || result.contains("No such container") {
                    self.errors["docker"] = "Failed to \(isRunning ? "stop" : "start") container"
                } else {
                    // Refresh container list after toggle
                    Task {
                        await fetchDocker()
                    }
                }
            }
        }
    }
    
    func toggleDockerEngine() {
        Task {
            if dockerEngineRunning {
                // Stop Docker engine
                let result = await executeCommand("osascript -e 'quit app \"Docker\"'")
                await MainActor.run {
                    if !result.contains("Error") {
                        self.dockerEngineRunning = false
                        self.dockerContainers = []
                    }
                }
            } else {
                // Start Docker engine
                let result = await executeCommand("open -a Docker")
                await MainActor.run {
                    if !result.contains("Error") {
                        // Wait a moment then check status
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            Task {
                                await self.fetchDocker()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func executeCommand(_ command: String) async -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "export PATH=\"/usr/local/bin:/opt/homebrew/bin:/usr/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH\" && \(command)"]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func updateTimestamp() {
        let df = DateFormatter()
        df.timeStyle = .medium
        df.dateStyle = .none
        lastUpdated = df.string(from: Date())
    }
}

final class PulumiMonitor: ObservableObject, @unchecked Sendable {
    @Published var currentStack: String = "Loading..."
    @Published var availableStacks: [String] = []
    @Published var lastUpdated: String = "Never"
    @Published var error: String?
    
    func fetchStacks() {
        Task {
            let whoami = await executeCommand("/usr/local/bin/pulumi whoami")
            let stacks = await executeCommand("/usr/local/bin/pulumi stack ls --json")
            
            await MainActor.run {
                if !whoami.isEmpty && !whoami.contains("error") {
                    self.currentStack = whoami.trimmingCharacters(in: .whitespaces)
                }
                
                if !stacks.isEmpty, let data = stacks.data(using: .utf8) {
                    do {
                        if let stackList = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            self.availableStacks = stackList.compactMap { $0["name"] as? String }
                        }
                    } catch {
                        self.error = "Failed to parse stacks"
                    }
                }
                
                self.updateTimestamp()
            }
        }
    }
    
    func selectStack(_ stack: String) {
        Task {
            let result = await executeCommand("/usr/local/bin/pulumi stack select \(stack)")
            await MainActor.run {
                if !result.contains("error") {
                    self.currentStack = stack
                    self.error = nil
                } else {
                    self.error = "Failed to select stack"
                }
                self.updateTimestamp()
            }
        }
    }
    
    private func executeCommand(_ command: String) async -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func updateTimestamp() {
        let df = DateFormatter()
        df.timeStyle = .medium
        df.dateStyle = .none
        lastUpdated = df.string(from: Date())
    }
}

final class GitHubMonitor: ObservableObject, @unchecked Sendable {
    @Published var currentUser: String = "Loading..."
    @Published var openPRs: [GitHubPR] = []
    @Published var lastUpdated: String = "Never"
    @Published var error: String?
    
    struct GitHubPR: Codable, Identifiable {
        let id = UUID()
        let number: Int
        let title: String
        let url: String
        
        private enum CodingKeys: String, CodingKey {
            case number, title, url
        }
    }
    
    func fetchStatus() {
        Task {
            let whoami = await executeCommand("/usr/local/bin/gh auth status")
            let prs = await executeCommand("/usr/local/bin/gh pr list --json number,title,url")
            
            await MainActor.run {
                if !whoami.isEmpty {
                    let lines = whoami.components(separatedBy: .newlines)
                    if let userLine = lines.first(where: { $0.contains("Logged in to") }) {
                        self.currentUser = userLine.replacingOccurrences(of: "✓ Logged in to github.com as ", with: "").trimmingCharacters(in: .whitespaces)
                    }
                }
                
                if !prs.isEmpty, let data = prs.data(using: .utf8) {
                    do {
                        self.openPRs = try JSONDecoder().decode([GitHubPR].self, from: data)
                    } catch {
                        self.error = "Failed to parse PRs"
                    }
                }
                
                self.updateTimestamp()
            }
        }
    }
    
    private func executeCommand(_ command: String) async -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func updateTimestamp() {
        let df = DateFormatter()
        df.timeStyle = .medium
        df.dateStyle = .none
        lastUpdated = df.string(from: Date())
    }
}

final class AzureMonitor: ObservableObject, @unchecked Sendable {
    @Published var currentSubscription: String = "Loading..."
    @Published var availableSubscriptions: [AzureSubscription] = []
    @Published var lastUpdated: String = "Never"
    @Published var error: String?
    
    struct AzureSubscription: Codable, Identifiable {
        let id: String
        let name: String
        let isDefault: Bool
        
        private enum CodingKeys: String, CodingKey {
            case id, name, isDefault
        }
    }
    
    func fetchSubscriptions() {
        Task {
            let subs = await executeCommand("/usr/local/bin/az account list --output json")
            
            await MainActor.run {
                if !subs.isEmpty, let data = subs.data(using: .utf8) {
                    do {
                        self.availableSubscriptions = try JSONDecoder().decode([AzureSubscription].self, from: data)
                        if let current = self.availableSubscriptions.first(where: { $0.isDefault }) {
                            self.currentSubscription = current.name
                        }
                    } catch {
                        self.error = "Failed to parse subscriptions: \(error.localizedDescription)"
                    }
                }
                
                self.updateTimestamp()
            }
        }
    }
    
    func selectSubscription(_ subscription: AzureSubscription) {
        Task {
            let result = await executeCommand("/usr/local/bin/az account set --subscription \(subscription.id)")
            await MainActor.run {
                if result.isEmpty || !result.contains("error") {
                    self.currentSubscription = subscription.name
                    self.error = nil
                    // Refresh the list to update isDefault flags
                    self.fetchSubscriptions()
                } else {
                    self.error = "Failed to switch subscription"
                }
                self.updateTimestamp()
            }
        }
    }
    
    private func executeCommand(_ command: String) async -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func updateTimestamp() {
        let df = DateFormatter()
        df.timeStyle = .medium
        df.dateStyle = .none
        lastUpdated = df.string(from: Date())
    }
}

final class KubectlMonitor: ObservableObject, @unchecked Sendable {
    @Published var currentContext: String = "Loading..."
    @Published var availableContexts: [String] = []
    @Published var lastUpdated: String = "Never"
    @Published var error: String?
    
    private var kubectlPath: String {
        let possiblePaths = [
            "/usr/local/bin/kubectl",
            "/opt/homebrew/bin/kubectl",
            "/usr/bin/kubectl"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Fallback to trying PATH
        return "kubectl"
    }
    
    func fetchContexts() {
        Task {
            let contexts = await executeCommand("\(kubectlPath) config get-contexts -o name")
            let current = await executeCommand("\(kubectlPath) config current-context")
            
            await MainActor.run {
                if contexts.contains("Error:") {
                    self.error = "kubectl not found or not configured"
                    self.currentContext = "Not available"
                } else if !contexts.isEmpty {
                    self.availableContexts = contexts.components(separatedBy: .newlines)
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    self.error = nil
                }
                
                if current.contains("Error:") {
                    if self.error == nil {
                        self.error = "No current context set"
                    }
                } else if !current.isEmpty {
                    self.currentContext = current.trimmingCharacters(in: .whitespaces)
                }
                
                self.updateTimestamp()
            }
        }
    }
    
    func switchContext(to context: String) {
        Task {
            let result = await executeCommand("\(kubectlPath) config use-context \(context)")
            await MainActor.run {
                if result.isEmpty || !result.contains("error") {
                    self.currentContext = context
                    self.error = nil
                } else {
                    self.error = "Failed to switch context"
                }
                self.updateTimestamp()
            }
        }
    }
    
    private func executeCommand(_ command: String) async -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func updateTimestamp() {
        let df = DateFormatter()
        df.timeStyle = .medium
        df.dateStyle = .none
        lastUpdated = df.string(from: Date())
    }
}

final class SystemMonitor: ObservableObject, @unchecked Sendable {
    @Published var currentOrg: String = "Loading..."
    @Published var currentIP: String = "Loading..."
    @Published var city: String = ""; @Published var country: String = ""
    @Published var cpuUsage: String = "Loading..."
    @Published var memoryUsage: String = "Loading..."
    @Published var diskUsage: String = "Loading..."
    @Published var audioDevice: String = "Loading..."
    @Published var currentlyPlaying: String = "No music playing"
    @Published var lastUpdated: String = "Never"
    
    var shortOrg: String {
        if currentOrg.starts(with: "AS") {
            let parts = currentOrg.components(separatedBy: " ")
            if parts.count > 1 {
                return parts.dropFirst().joined(separator: " ")
            }
        }
        return currentOrg
    }

    private var timer: Timer?
    private var musicTimer: Timer?
    private let refreshInterval: TimeInterval = 60
    private let musicRefreshInterval: TimeInterval = 2

    struct IPInfo: Codable {
        let ip: String
        let city: String
        let region: String
        let country: String
        let loc: String
        let org: String
        let postal: String
        let timezone: String
    }

    func startMonitoring() {
        updateTimestamp()
        fetchIPInfo()
        fetchSystemInfo()
        
        // Main timer for IP and system info (every 60 seconds)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchIPInfo()
                self?.fetchSystemInfoWithoutMusic() // Exclude music from main timer
            }
        }
        
        // Separate timer for music (every 10 seconds)
        musicTimer?.invalidate()
        musicTimer = Timer.scheduledTimer(withTimeInterval: musicRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchMusicInfo()
            }
        }
    }
    
    func fetchSystemInfo() {
        Task {
            let cpu = await executeSystemCommand("top -l 2 | grep 'CPU usage' | tail -1 | awk '{print $3}' | sed 's/%//'")
            let memory = await executeSystemCommand("vm_stat | awk '/Pages free:/{free=$3} /Pages active:/{active=$3} /Pages inactive:/{inactive=$3} /Pages speculative:/{spec=$3} /Pages wired down:/{wired=$4} END{total=free+active+inactive+spec+wired; used=total-free-spec; printf \"%.1f\", (used/total)*100}'")
            let disk = await executeSystemCommand("df -h / | tail -1 | awk '{print $3\"/\"$2\" (\"$5\" used)\"}'")
            let audio = await executeSystemCommand("system_profiler SPAudioDataType | awk '/Output Source: Default/{found=1} found && /^[[:space:]]*[A-Za-z].*:$/{print $1; exit}' | sed 's/://g' || echo 'Built-in Output'")
            
            await MainActor.run {
                self.cpuUsage = cpu.isEmpty ? "Unknown" : "\(cpu.trimmingCharacters(in: .whitespacesAndNewlines))%"
                self.memoryUsage = memory.isEmpty ? "Unknown" : "\(memory.trimmingCharacters(in: .whitespacesAndNewlines))%"
                self.diskUsage = disk.isEmpty ? "Unknown" : disk.trimmingCharacters(in: .whitespacesAndNewlines)
                self.audioDevice = audio.isEmpty ? "Built-in Output" : audio.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Also fetch music info initially
        fetchMusicInfo()
    }
    
    func fetchSystemInfoWithoutMusic() {
        Task {
            let cpu = await executeSystemCommand("top -l 2 | grep 'CPU usage' | tail -1 | awk '{print $3}' | sed 's/%//'")
            let memory = await executeSystemCommand("vm_stat | awk '/Pages free:/{free=$3} /Pages active:/{active=$3} /Pages inactive:/{inactive=$3} /Pages speculative:/{spec=$3} /Pages wired down:/{wired=$4} END{total=free+active+inactive+spec+wired; used=total-free-spec; printf \"%.1f\", (used/total)*100}'")
            let disk = await executeSystemCommand("df -h / | tail -1 | awk '{print $3\"/\"$2\" (\"$5\" used)\"}'")
            let audio = await executeSystemCommand("system_profiler SPAudioDataType | awk '/Output Source: Default/{found=1} found && /^[[:space:]]*[A-Za-z].*:$/{print $1; exit}' | sed 's/://g' || echo 'Built-in Output'")
            
            await MainActor.run {
                self.cpuUsage = cpu.isEmpty ? "Unknown" : "\(cpu.trimmingCharacters(in: .whitespacesAndNewlines))%"
                self.memoryUsage = memory.isEmpty ? "Unknown" : "\(memory.trimmingCharacters(in: .whitespacesAndNewlines))%"
                self.diskUsage = disk.isEmpty ? "Unknown" : disk.trimmingCharacters(in: .whitespacesAndNewlines)
                self.audioDevice = audio.isEmpty ? "Built-in Output" : audio.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    
    func fetchMusicInfo() {
        Task {
            let music = await executeSystemCommand("osascript -e 'set musicInfo to \"\"' -e 'try' -e 'tell application \"Spotify\"' -e 'if player state is playing then' -e 'set musicInfo to (name of current track & \" - \" & artist of current track)' -e 'end if' -e 'end tell' -e 'end try' -e 'if musicInfo is \"\" then' -e 'try' -e 'tell application \"Music\"' -e 'if player state is playing then' -e 'set musicInfo to (name of current track & \" - \" & artist of current track)' -e 'end if' -e 'end tell' -e 'end try' -e 'end if' -e 'if musicInfo is \"\" then' -e 'return \"No music playing\"' -e 'else' -e 'return musicInfo' -e 'end if'")
            
            await MainActor.run {
                self.currentlyPlaying = music.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    
    private func executeSystemCommand(_ command: String) async -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "export PATH=\"/usr/local/bin:/opt/homebrew/bin:$PATH\" && \(command)"]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    func fetchIPInfo() {
        guard let url = URL(string: "https://ipinfo.io/json") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                Task { @MainActor in
                    self?.currentOrg = "Error: \(error.localizedDescription)"
                    self?.updateTimestamp()
                }
                return
            }
            guard let data = data else {
                Task { @MainActor in
                    self?.currentOrg = "No data"
                    self?.updateTimestamp()
                }
                return
            }
            do {
                let ipInfo = try JSONDecoder().decode(IPInfo.self, from: data)
                Task { @MainActor in
                    self?.currentOrg = ipInfo.org
                    self?.currentIP = ipInfo.ip
                    self?.city = ipInfo.city
                    self?.country = ipInfo.country
                    self?.updateTimestamp()
                }
            } catch {
                Task { @MainActor in
                    self?.currentOrg = "Parse error"
                    self?.updateTimestamp()
                }
            }
        }
        task.resume()
    }

    private func updateTimestamp() {
        let df = DateFormatter()
        df.timeStyle = .medium
        df.dateStyle = .none
        lastUpdated = df.string(from: Date())
    }

    deinit { 
        timer?.invalidate()
        musicTimer?.invalidate()
    }
}
