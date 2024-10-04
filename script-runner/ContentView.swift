//
//  ContentView.swift
//  script-runner
//
//  Created by Canh Duong on 4/10/24.
//

import SwiftUI

struct ContentView: View {
    @State private var scriptContent: String = ""
       @State private var executionResult: String = ""
       @State private var isImporting: Bool = false
       @State private var errorMessage: String?

       var body: some View {
           VStack {
               Text("Script Content")
                   .font(.headline)
               TextEditor(text: $scriptContent)
                   .frame(height: 200)
                   .border(Color.gray, width: 1)
                   .padding()

               HStack {
                   Button("Load Script") {
                       isImporting = true
                   }
                   .padding()

                   Button("Run Script") {
                       runScript()
                   }
                   .padding()

               }

               Text("Execution Result")
                   .font(.headline)
               TextEditor(text: $executionResult)
                   .frame(height: 200)
                   .border(Color.gray, width: 1)
                   .padding()
           }
           .padding()
           .fileImporter(
               isPresented: $isImporting,
               allowedContentTypes: [.shellScript],
               allowsMultipleSelection: false
           ) { result in
               switch result {
               case .success(let files):
                   if let file = files.first {
                       loadScript(from: file)
                   }
               case .failure(let error):
                   print("Error importing file: \(error.localizedDescription)")
               }
           }
       }

       private func loadScript(from url: URL) {
           guard url.startAccessingSecurityScopedResource() else {
               errorMessage = "Failed to access the file."
               return
           }
           defer { url.stopAccessingSecurityScopedResource() }

           do {
               scriptContent = try String(contentsOf: url, encoding: .utf8)
           } catch {
               errorMessage = "Error reading file: \(error.localizedDescription)"
           }
       }

       private func runScript() {
           let process = Process()
           process.executableURL = URL(fileURLWithPath: "/bin/bash")
           process.arguments = ["-c", scriptContent]

           let pipe = Pipe()
           process.standardOutput = pipe
           process.standardError = pipe

           do {
               try process.run()

               let data = pipe.fileHandleForReading.readDataToEndOfFile()
               if let output = String(data: data, encoding: .utf8) {
                   executionResult = output
               } else {
                   executionResult = "No output or unable to decode output."
               }

               process.waitUntilExit()
           } catch {
               errorMessage = "Error running script: \(error.localizedDescription)"
           }
       }
}

#Preview {
    ContentView()
}
