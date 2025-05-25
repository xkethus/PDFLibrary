// MetadataPanel.swift
import SwiftUI

struct MetadataPanel: View {
    @Binding var selectedPDF: PDFFile?
    @Binding var editableMetadata: [String: String]
    @Binding var isFromLibrary: Bool
    @Binding var selectedCollections: Set<UUID>
    @Binding var collections: [PDFCollection]
    let loadFromDatabase: () -> Void
    let loadCollections: () -> Void

    var body: some View {
        let collectionTagsView = Group {
            if let pdf = selectedPDF {
                let associatedCollections = PDFDatabase.shared.getCollections(forPDF: pdf)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(associatedCollections) { collection in
                            HStack(spacing: 4) {
                                Text(collection.name)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)

                                Button(action: {
                                    PDFDatabase.shared.unlinkPDF(from: collection, pdf: pdf)
                                    loadCollections()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(4)
                        }
                    }
                }
            }
        }

        return VStack(alignment: .leading, spacing: 10) {
            if let pdf = selectedPDF {
                PDFPreview(url: pdf.url)
                    .frame(minHeight: 300)

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
                        TextField("Temas", text: Binding(
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

                        Text("Colecciones")
                            .font(.subheadline)
                            .padding(.top, 6)

                        collectionTagsView

                        Menu {
                            ForEach(collections.filter { !PDFDatabase.shared.getCollections(forPDF: pdf).contains($0) }) { collection in
                                Button(collection.name) {
                                    PDFDatabase.shared.linkPDFToCollection(pdfID: pdf.id, collectionID: collection.id)
                                    loadCollections()
                                }
                            }
                        } label: {
                            Label("Agregar a colección", systemImage: "plus.circle")
                        }
                        .padding(.top, 4)

                        HStack {
                            if isFromLibrary {
                                Button(action: {
                                    if let selected = selectedPDF {
                                        PDFDatabase.shared.updatePDF(file: selected, meta: editableMetadata)
                                        loadFromDatabase()
                                    }
                                }) {
                                    Image(systemName: "square.and.arrow.down")
                                }
                                Button(action: {
                                    if let selected = selectedPDF {
                                        PDFDatabase.shared.deletePDF(file: selected)
                                        selectedPDF = nil
                                        loadFromDatabase()
                                    }
                                }) {
                                    Image(systemName: "trash")
                                }
                            } else {
                                Button(action: {
                                    if let selected = selectedPDF, !(editableMetadata["Title"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                                        PDFDatabase.shared.insertPDF(file: selected, meta: editableMetadata)
                                        for cid in selectedCollections {
                                            PDFDatabase.shared.linkPDFToCollection(pdfID: selected.id, collectionID: cid)
                                        }
                                        selectedCollections.removeAll()
                                        loadFromDatabase()
                                    }
                                }) {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(5)
                }
            } else {
                Text("Selecciona un PDF para ver la vista previa")
                    .padding()
            }
        }
        .frame(minWidth: 500)
    }
}
