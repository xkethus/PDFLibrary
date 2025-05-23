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

    var filteredLibrary: [PDFFile] {
        if searchText.isEmpty { return libraryPDFs }
        return libraryPDFs.filter { pdf in
            if let doc = PDFDocument(url: pdf.url) {
                let meta = doc.metadata
                return meta.values.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
            return false
        }
    }

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Button("📂 Abrir carpeta") {
                        selectFolder()
                    }
                    Button("🧹 Limpiar carpeta") {
                        folderPDFs.removeAll()
                    }
                }
                .padding(.bottom, 5)

                TextField("🔍 Buscar en biblioteca...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom], 5)

                Text("📚 Biblioteca")
                    .font(.headline)
                List(filteredLibrary) { pdf in
                    let title = pdf.metadata?["Title"] ?? pdf.fileName

                    Text(title)
                        .onTapGesture {
                            selectedPDF = pdf
                            isFromLibrary = true
                            editableMetadata = pdf.metadata ?? [:]
                        }
                }

                Divider()

                Text("📁 Archivos en carpeta")
                    .font(.headline)
                List(folderPDFs) { pdf in
                    let title = pdf.fileName
                    Text(title)
                        .onTapGesture {
                            selectedPDF = pdf
                            isFromLibrary = false
                            if let doc = PDFDocument(url: pdf.url) {
                                editableMetadata = doc.metadata
                            }
                        }
                }
            }
            .frame(minWidth: 320)

            Divider()

            if let pdf = selectedPDF {
                VStack(alignment: .leading, spacing: 10) {
    PDFPreview(url: pdf.url)
        .frame(minHeight: 400)

    GroupBox(label: Text("Editar metadatos")) {
        VStack(alignment: .leading) {
            TextField("Título", text: Binding(
                get: { editableMetadata["Title"] ?? "" },
                set: { editableMetadata["Title"] = $0 }
            ))
            TextField("Autor", text: Binding(
                get: { editableMetadata["Author"] ?? "" },
                set: { editableMetadata["Author"] = $0 }
            ))
            TextField("Asunto", text: Binding(
                get: { editableMetadata["Subject"] ?? "" },
                set: { editableMetadata["Subject"] = $0 }
            ))
            TextField("Palabras clave", text: Binding(
                get: { editableMetadata["Keywords"] ?? "" },
                set: { editableMetadata["Keywords"] = $0 }
            ))
            TextField("Fecha de creación", text: Binding(
                get: { editableMetadata["CreationDate"] ?? "" },
                set: { editableMetadata["CreationDate"] = $0 }
            ))
            TextField("Editorial", text: Binding(
                get: { editableMetadata["Producer"] ?? "" },
                set: { editableMetadata["Producer"] = $0 }
            ))

            HStack {
                if isFromLibrary {
                    Button("💾 Actualizar") {
                        if let selected = selectedPDF {
                            PDFDatabase.shared.updatePDF(file: selected, meta: editableMetadata)
                            loadFromDatabase()
                        }
                    }
                    Button("🗑 Eliminar de biblioteca") {
                        if let selected = selectedPDF {
                            PDFDatabase.shared.deletePDF(file: selected)
                            selectedPDF = nil
                            loadFromDatabase()
                        }
                    }
                } else {
                    Button("➕ Añadir a biblioteca") {
                        if let selected = selectedPDF, !(editableMetadata["Title"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                            PDFDatabase.shared.insertPDF(file: selected, meta: editableMetadata)
                            loadFromDatabase()
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding(5)
    }
}
.frame(minWidth: 700)
            } else {
                Text("Selecciona un PDF para ver la vista previa")
                    .frame(minWidth: 700)
            }
        }
        .frame(minWidth: 1100, minHeight: 600)
        .onAppear {
            loadFromDatabase()
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

    

    
    }

      
