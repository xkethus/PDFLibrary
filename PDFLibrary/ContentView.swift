// ContentView.swift
import SwiftUI
import PDFKit
import Foundation

struct ContentView: View {
    @State private var folderPDFs: [PDFFile] = []
    @State private var libraryPDFs: [PDFFile] = []
    @State private var selectedPDF: PDFFile?
    @State private var editableMetadata: [String: String] = [:]
    @State private var isFromLibrary: Bool = false
    @State private var searchText: String = ""
    @State private var collections: [PDFCollection] = []
    @State private var selectedCollection: PDFCollection? = PDFCollection(id: UUID(), name: "Mi biblioteca")
    @State private var collectionPDFs: [PDFFile] = []
    @State private var showNewCollectionField = false
    @State private var newCollectionName = ""
    @State private var selectedCollections: Set<UUID> = []

    var displayedLibrary: [PDFFile] {
        if let collection = selectedCollection, collection.name != "Mi biblioteca" {
            return PDFDatabase.shared.getPDFs(forCollection: collection)
        } else {
            return libraryPDFs
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            CollectionSidebar(
                collections: $collections,
                selectedCollection: $selectedCollection,
                selectedCollections: $selectedCollections,
                showNewCollectionField: $showNewCollectionField,
                newCollectionName: $newCollectionName,
                folderPDFs: $folderPDFs,
                selectedPDF: $selectedPDF,
                editableMetadata: $editableMetadata,
                isFromLibrary: $isFromLibrary,
                loadCollections: loadCollections,
                selectFolder: selectFolder
            )

            Divider()

            PDFListPanel(
                displayedLibrary: displayedLibrary,
                selectedCollection: $selectedCollection,
                selectedPDF: $selectedPDF,
                editableMetadata: $editableMetadata,
                isFromLibrary: $isFromLibrary
            )

            Divider()

            MetadataPanel(
                selectedPDF: $selectedPDF,
                editableMetadata: $editableMetadata,
                isFromLibrary: $isFromLibrary,
                selectedCollections: $selectedCollections,
                collections: $collections,
                loadFromDatabase: loadFromDatabase,
                loadCollections: loadCollections
            )
        }
        .frame(minWidth: 1200, minHeight: 600)
        .onAppear {
            loadCollections()
            loadFromDatabase()
        }
        .onChange(of: selectedCollection) { newValue in
            if let collection = newValue, collection.name != "Mi biblioteca" {
                collectionPDFs = PDFDatabase.shared.getPDFs(forCollection: collection)
            } else {
                collectionPDFs = []
            }
        }
    }

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            if let folderURL = panel.url {
                loadPDFFiles(from: folderURL)
            }
        }
    }

    func loadPDFFiles(from folderURL: URL) {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            let pdfs = fileURLs.filter { $0.pathExtension.lowercased() == "pdf" }
            self.folderPDFs = pdfs.map { PDFFile(url: $0) }
        } catch {
            print("Error al leer archivos: \(error)")
        }
    }

    func loadFromDatabase() {
        self.libraryPDFs = PDFDatabase.shared.fetchAllPDFs()
    }

    func loadCollections() {
        var list = PDFDatabase.shared.fetchCollections()
        list.insert(PDFCollection(id: UUID(), name: "Mi biblioteca"), at: 0)
        collections = list
    }
}

struct PDFCollection: Identifiable, Equatable {
    let id: UUID
    let name: String
}
