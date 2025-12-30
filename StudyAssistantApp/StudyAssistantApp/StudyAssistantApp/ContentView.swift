//
//  ContentView.swift
//  StudyAssistantApp
//
//  Created by Adam Lisnell on 2025-12-04.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isProcessing = false
    @State private var outputText = "Drop your notes here to get started!"
    @State private var dragOver = false
    @State private var processedCount = 0
    @State private var showSettings = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success
    @State private var showHistory = false
    @State private var processingHistory: [ProcessedFile] = []
    @State private var previewURL: URL?
    @State private var showPreview = false
    
    var body: some View {
        ZStack {
            (isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color(red: 0.96, green: 0.96, blue: 0.98))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    HStack {
                        Button(action: { showHistory.toggle() }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20))
                                .foregroundColor(isDarkMode ? .white : .gray)
                                .frame(width: 36, height: 36)
                                .background(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Processing History")
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Image("NotePalLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                            
                            Text("NotePal")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: { isDarkMode.toggle() }) {
                                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(isDarkMode ? .yellow : .gray)
                                    .frame(width: 36, height: 36)
                                    .background(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .help("Toggle Dark Mode")
                            
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(isDarkMode ? .white : .gray)
                                    .frame(width: 36, height: 36)
                                    .background(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut(",", modifiers: .command)
                            .help("Settings (⌘,)")
                        }
                    }
                    
                    Text("Transform your notes into study materials")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isDarkMode ? .gray : .secondary)
                }
                .padding(.top, 15)
                
                if processedCount > 0 {
                    HStack(spacing: 15) {
                        StatsCard(icon: "checkmark.circle.fill", value: "\(processedCount)", label: "Processed", color: .green, isDark: isDarkMode)
                        StatsCard(icon: "doc.fill", value: "Multi", label: "Format", color: .blue, isDark: isDarkMode)
                        StatsCard(icon: "sparkles", value: "AI", label: "Powered", color: .purple, isDark: isDarkMode)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: processedCount)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color.white)
                        .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            dragOver ? (isDarkMode ? Color.white : Color.black) : Color.gray.opacity(0.3),
                            style: StrokeStyle(lineWidth: dragOver ? 3 : 2, dash: [10, 5])
                        )
                    
                    VStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(dragOver ? (isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1)) : Color.gray.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 35))
                                .foregroundColor(dragOver ? (isDarkMode ? .white : .black) : .gray)
                        }
                        
                        Text("Drop notes here")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        Text("or click Process Notes below")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 8) {
                            ForEach(["txt", "md", "pdf", "docx"], id: \.self) { format in
                                Text(".\(format)")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(isDarkMode ? Color.white.opacity(0.2) : Color.black)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(30)
                }
                .frame(height: 240)
                .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
                    handleDrop(providers: providers)
                }
                
                HStack(spacing: 12) {
                    Button(action: processNotes) {
                        HStack(spacing: 10) {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isProcessing ? "Processing..." : "Process Notes")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isDarkMode ? Color.white : Color.black)
                        .foregroundColor(isDarkMode ? .black : .white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .disabled(isProcessing)
                    .buttonStyle(.plain)
                    .keyboardShortcut("p", modifiers: .command)
                    .help("Process notes (⌘P)")
                    
                    Button(action: openNotesFolder) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Open")
                                .fontWeight(.semibold)
                        }
                        .frame(width: 120, height: 50)
                        .background(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color.white)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("o", modifiers: .command)
                    .help("Open folder (⌘O)")
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Console Output", systemImage: "terminal.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        Spacer()
                        
                        Button(action: {
                            outputText = "Console cleared"
                            showToastNotification("Console cleared", type: .info)
                        }) {
                            Text("Clear")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("k", modifiers: .command)
                        .help("Clear console (⌘K)")
                    }
                    
                    ScrollView {
                        Text(outputText)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .foregroundColor(isDarkMode ? .white : .black)
                            .padding(12)
                    }
                    .frame(height: 180)
                    .background(isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(14)
                .background(isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
            
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage, type: toastType)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showToast)
                }
                .padding(.bottom, 20)
            }
        }
        .frame(width: 700, height: 750)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showSettings) {
            SettingsView(isDarkMode: $isDarkMode)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(history: $processingHistory, isDarkMode: isDarkMode, onPreview: { url in
                previewURL = url
                showPreview = true
            })
        }
        .quickLookPreview($previewURL)
    }
    
    func showToastNotification(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showToast = false
            }
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url else {
                    DispatchQueue.main.async {
                        self.outputText = "Could not read file"
                        self.showToastNotification("Failed to read file", type: .error)
                    }
                    return
                }
                
                let ext = url.pathExtension.lowercased()
                let supportedTypes = ["txt", "md", "markdown", "pdf", "docx", "doc"]
                
                guard supportedTypes.contains(ext) else {
                    DispatchQueue.main.async {
                        self.outputText = "Unsupported file type: .\(ext)\n\nSupported: .txt, .md, .pdf, .docx"
                        self.showToastNotification("Unsupported file type: .\(ext)", type: .error)
                    }
                    return
                }
                
                let homeDir = FileManager.default.homeDirectoryForCurrentUser
                let incomingDir = homeDir
                    .appendingPathComponent("study_assistant")
                    .appendingPathComponent("notes")
                    .appendingPathComponent("incoming")
                
                try? FileManager.default.createDirectory(at: incomingDir, withIntermediateDirectories: true)
                
                let destination = incomingDir.appendingPathComponent(url.lastPathComponent)
                
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    
                    try FileManager.default.copyItem(at: url, to: destination)
                    
                    DispatchQueue.main.async {
                        self.outputText = "Added: \(url.lastPathComponent)\n\nReady to process!"
                        self.showToastNotification("File added: \(url.lastPathComponent)", type: .success)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.outputText = "Error: \(error.localizedDescription)"
                        self.showToastNotification("Error adding file", type: .error)
                    }
                }
            }
        }
        return true
    }
    
    func processNotes() {
        isProcessing = true
        outputText = "NotePal is processing your notes...\n\n"
        let startTime = Date()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["-c", """
                cd /Users/adamlisnell/study_assistant && \
                source .venv/bin/activate && \
                study-assistant process
                """]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            var capturedOutput = ""
            
            do {
                try task.run()
                
                let handle = pipe.fileHandleForReading
                handle.readabilityHandler = { fileHandle in
                    let data = fileHandle.availableData
                    if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                        capturedOutput += output
                        DispatchQueue.main.async {
                            self.outputText += output
                        }
                    }
                }
                
                task.waitUntilExit()
                handle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    let duration = Date().timeIntervalSince(startTime)
                    
                    if task.terminationStatus == 0 {
                        self.outputText += "\n\nProcessing completed successfully!"
                        self.processedCount += 1
                        self.showToastNotification("Processing completed!", type: .success)
                        
                        // Parse filename and PDF path
                        var filename = "Recent processing"
                        var pdfPath: URL?
                        
                        if let match = capturedOutput.range(of: "Processing: ([^\n]+)", options: .regularExpression) {
                            filename = String(capturedOutput[match]).replacingOccurrences(of: "Processing: ", with: "")
                        }
                        
                        if let pdfMatch = capturedOutput.range(of: "PDF saved to (.+\\.pdf)", options: .regularExpression) {
                            let pdfPathString = String(capturedOutput[pdfMatch])
                                .replacingOccurrences(of: "✓ PDF saved to ", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            pdfPath = URL(fileURLWithPath: pdfPathString)
                        }
                        
                        let processed = ProcessedFile(
                            filename: filename,
                            timestamp: Date(),
                            success: true,
                            duration: duration,
                            outputPath: pdfPath
                        )
                        self.processingHistory.insert(processed, at: 0)
                    } else {
                        self.outputText += "\n\nProcessing failed"
                        self.showToastNotification("Processing failed", type: .error)
                        
                        let processed = ProcessedFile(
                            filename: "Failed processing",
                            timestamp: Date(),
                            success: false,
                            duration: duration,
                            outputPath: nil
                        )
                        self.processingHistory.insert(processed, at: 0)
                    }
                    self.isProcessing = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.outputText += "\nError: \(error.localizedDescription)"
                    self.showToastNotification("Error: \(error.localizedDescription)", type: .error)
                    self.isProcessing = false
                }
            }
        }
    }
    
    func openNotesFolder() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let notesDir = homeDir.appendingPathComponent("study_assistant/notes")
        NSWorkspace.shared.open(notesDir)
        showToastNotification("Opened notes folder", type: .info)
    }
}

struct ProcessedFile: Identifiable {
    let id = UUID()
    let filename: String
    let timestamp: Date
    let success: Bool
    let duration: TimeInterval
    let outputPath: URL?
}

struct HistoryView: View {
    @Binding var history: [ProcessedFile]
    let isDarkMode: Bool
    let onPreview: (URL) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Processing History")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            
            Divider()
            
            if history.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No processing history yet")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isDarkMode ? .white : .black)
                    
                    Text("Process some notes to see them here!")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(history) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(item.success ? .green : .red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.filename)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(isDarkMode ? .white : .black)
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    Text(item.timestamp, style: .relative)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    
                                    Text("•")
                                        .foregroundColor(.gray)
                                    
                                    Text(String(format: "%.1fs", item.duration))
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            if item.success, let outputPath = item.outputPath {
                                Button(action: {
                                    onPreview(outputPath)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "eye.fill")
                                            .font(.system(size: 14))
                                        Text("Preview")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .help("Quick Look Preview")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 550, height: 400)
        .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color(red: 0.96, green: 0.96, blue: 0.98))
    }
}

enum ToastType {
    case success, error, info
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(type.color)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isDarkMode: Bool
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("selectedModel") private var selectedModel: String = "gpt-4o-mini"
    @AppStorage("incomingPath") private var incomingPath: String = "~/Desktop/NotePal/process_notes"
    @AppStorage("outputPath") private var outputPath: String = "~/Desktop/NotePal/Generated_study_material"
    
    @State private var showSaveAlert = false
    
    let models = ["gpt-4o-mini", "gpt-4o", "gpt-4-turbo"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OpenAI Configuration")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            SecureField("sk-...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 13, design: .monospaced))
                            
                            Text("Stored securely and used locally only")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $selectedModel) {
                                ForEach(models, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .toggleStyle(.switch)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Folder Configuration")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Incoming Notes Folder")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("~/Desktop/NotePal/process_notes", text: $incomingPath)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                
                                Button("Browse") {
                                    selectFolder(for: .incoming)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Output Folder")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("~/Desktop/NotePal/Generated_study_material", text: $outputPath)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                
                                Button("Browse") {
                                    selectFolder(for: .output)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Keyboard Shortcuts")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isDarkMode ? .white : .black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ShortcutRow(keys: "⌘P", description: "Process notes", isDark: isDarkMode)
                            ShortcutRow(keys: "⌘O", description: "Open notes folder", isDark: isDarkMode)
                            ShortcutRow(keys: "⌘K", description: "Clear console", isDark: isDarkMode)
                            ShortcutRow(keys: "⌘,", description: "Open settings", isDark: isDarkMode)
                        }
                    }
                }
                .padding(24)
            }
            
            Divider()
            
            HStack {
                Button("Reset to Default") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .tint(isDarkMode ? .white : .black)
            }
            .padding(24)
        }
        .frame(width: 550, height: 650)
        .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.14) : Color(red: 0.96, green: 0.96, blue: 0.98))
        .alert("Settings Saved", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Settings saved to .env file. Restart for changes to take effect.")
        }
    }
    
    enum FolderType {
        case incoming, output
    }
    
    func selectFolder(for type: FolderType) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                switch type {
                case .incoming:
                    incomingPath = url.path
                case .output:
                    outputPath = url.path
                }
            }
        }
    }
    
    func saveSettings() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let envPath = homeDir.appendingPathComponent("study_assistant/.env")
        
        let envContent = """
        # OpenAI Configuration
        OPENAI_API_KEY=\(apiKey)
        OPENAI_MODEL=\(selectedModel)
        
        # Folder Configuration
        NOTES_INCOMING_DIR=\(incomingPath)
        NOTES_OUTPUT_DIR=\(outputPath)
        PROCESSED_INDEX_PATH=\(outputPath)/processed_index.json
        
        # Application Settings
        LOG_LEVEL=INFO
        MAX_REQUESTS_PER_MINUTE=50
        """
        
        do {
            try envContent.write(to: envPath, atomically: true, encoding: .utf8)
            showSaveAlert = true
        } catch {
            print("Failed to save: \(error)")
        }
        
        dismiss()
    }
    
    func resetToDefaults() {
        apiKey = ""
        selectedModel = "gpt-4o-mini"
        incomingPath = "~/Desktop/NotePal/process_notes"
        outputPath = "~/Desktop/NotePal/Generated_study_material"
        isDarkMode = false
    }
}

struct ShortcutRow: View {
    let keys: String
    let description: String
    let isDark: Bool
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(6)
            
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(isDark ? .gray : .secondary)
            
            Spacer()
        }
    }
}

struct StatsCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let isDark: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isDark ? .white : .black)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isDark ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(isDark ? 0.3 : 0.08), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
