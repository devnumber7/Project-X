//
//  ContentView.swift
//  ProjectX
//
//  Created by Aryan Palit on 12/20/24.
//


import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PDFKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Document]
    @State private var isPickerPresented = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let pdfparse = PDFReader() // Your backend PDF parsing logic

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        // Show the PDF if available
                        if let pdfURL = item.pdfURL, FileManager.default.fileExists(atPath: pdfURL.path) {
                            VStack {
                                // Display the PDF
                                PDFViewUI(url: pdfURL)
                                    .navigationTitle(item.getDocumentName() ?? "Untitled")
                                    .frame(maxWidth: .infinity, maxHeight: 800)

                                // Read PDF button
                                Button("Read PDF") {
                                    readPDF(from: pdfURL, title: item.getDocumentName() ?? "Untitled")
                                }
                                .padding()

                                // Optionally, display extracted text within the same view
                                /*
                                ScrollView {
                                    if extractedText.isEmpty {
                                        Text("Press 'Read PDF' to extract the text.")
                                            .foregroundColor(.gray)
                                            .padding()
                                    } else {
                                        Text(extractedText)
                                            .padding()
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                */
                            }
                        }
                        else {
                            Text("No PDF available")
                                .navigationTitle("Document Detail")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    label: {
                        VStack(alignment: .leading) {
                            Text(item.getDocumentName() ?? "Untitled")
                                .font(.headline)
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .onAppear {
                print("Current items count: \(items.count)")
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: { isPickerPresented = true }) {
                        Label("Add Document", systemImage: "plus")
                    }

                    Button(action: deleteAllItems) {
                        Label("Clear All", systemImage: "trash")
                    }
                }
            }
        } detail: {
            Text("Select Document")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    /// Handles the file import process.
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedFile = urls.first else {
                print("No file selected.")
                return
            }
            // Verify the selected file is a PDF
            guard selectedFile.pathExtension.lowercased() == "pdf" else {
                alertMessage = "Selected file is not a PDF."
                showAlert = true
                print("Selected file is not a PDF.")
                return
            }
            
            // Start accessing a security-scoped resource.
            guard selectedFile.startAccessingSecurityScopedResource() else {
                alertMessage = "Couldn't access the selected file."
                showAlert = true
                print("Couldn't access the selected file.")
                return
            }
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            
            // Copy the PDF to the app's Documents directory for persistent access
            let destinationURL = getDocumentsDirectory().appendingPathComponent(selectedFile.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                    print("Existing PDF removed at: \(destinationURL)")
                }
                try FileManager.default.copyItem(at: selectedFile, to: destinationURL)
                print("Copied PDF to: \(destinationURL)")
                withAnimation {
                    let newItem = Document(timestamp: Date(), pdfURL: destinationURL)
                    modelContext.insert(newItem)
                    print("Inserted new Document: \(newItem)")
                    print("Current items count after insertion: \(items.count)")
                }
            } catch {
                alertMessage = "Failed to copy PDF: \(error.localizedDescription)"
                showAlert = true
                print("Failed to copy PDF: \(error.localizedDescription)")
            }
        case .failure(let error):
            alertMessage = "File import failed: \(error.localizedDescription)"
            showAlert = true
            print("File import failed: \(error.localizedDescription)")
        }
    }

    /// Deletes selected documents.
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = items[index]
                // Optionally, delete the PDF file from disk
                if let pdfURL = item.pdfURL {
                    do {
                        try FileManager.default.removeItem(at: pdfURL)
                        print("Deleted PDF file at: \(pdfURL)")
                    } catch {
                        print("Failed to delete PDF file: \(error.localizedDescription)")
                    }
                }
                modelContext.delete(item)
            }
        }
    }

    /// Deletes all documents.
    private func deleteAllItems() {
        withAnimation {
            for item in items {
                // Optionally, delete the PDF file from disk
                if let pdfURL = item.pdfURL {
                    do {
                        try FileManager.default.removeItem(at: pdfURL)
                        print("Deleted PDF file at: \(pdfURL)")
                    } catch {
                        print("Failed to delete PDF file: \(error.localizedDescription)")
                    }
                }
                modelContext.delete(item)
            }
        }
    }

    /// Helper to get the app's Documents directory.
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Handles reading the PDF and opening the parsed text window.
    private func readPDF(from url: URL, title: String) {
        do {
            let text = try pdfparse.extractText(from: url)
            // Open the ParsedTextView in a new window
            WindowManager.shared.openNewWindow(
                ParsedTextView(text: text, title: title),
                title: "\(title) - Parsed Text"
            )
        } catch {
            // Handle extraction errors
            let errorMessage = error.localizedDescription
            // Show the error in an alert
            alertMessage = "Failed to read PDF: \(errorMessage)"
            showAlert = true
            print("Failed to read PDF: \(errorMessage)")
        }
    }
}

//this is the code that deals with pdf display
struct PDFViewUI: NSViewRepresentable {
    typealias NSViewType = PDFView

    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysAsBook = false

        loadPDF(into: pdfView)

        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        // If the document is already set, do not reload it
        if nsView.document?.documentURL != url {
            loadPDF(into: nsView)
        }
    }

    /// Loads the PDF document into the given PDFView.
    /// - Parameter pdfView: The PDFView to load the document into.
    private func loadPDF(into pdfView: PDFView) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("PDF file does not exist at path: \(url.path)")
            return
        }

        guard let document = PDFDocument(url: url) else {
            print("Failed to load PDF document from URL: \(url)")
            return
        }

        pdfView.document = document
        print("Loaded PDF: \(url)")
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: Document.self, inMemory: true)
    }
}
