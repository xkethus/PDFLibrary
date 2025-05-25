import SwiftUI
import PDFKit

struct CollectionSidebar: View {
    @Binding var collections: [PDFCollection]
    @Binding var selectedCollection: PDFCollection?
    @Binding var selectedCollections: Set<UUID>
    @Binding var showNewCollectionField: Bool
    @Binding var newCollectionName: String
    @Binding var folderPDFs: [PDFFile]
    @Binding var selectedPDF: PDFFile?
    @Binding var editableMetadata: [String: String]
    @Binding var isFromLibrary: Bool

    var loadCollections: () -> Void
    var selectFolder: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Colecciones")
                    .font(.headline)
                Spacer()
                Button(action: { showNewCollectionField.toggle() }) {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal)

            if showNewCollectionField {
                HStack {
                    TextField("Nueva colección", text: $newCollectionName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        if !newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty {
                            PDFDatabase.shared.insertCollection(name: newCollectionName)
                            newCollectionName = ""
                            showNewCollectionField = false
                            loadCollections()
                        }
                    }) {
                        Image(systemName: "checkmark")
                    }
                }
                .padding(.horizontal)
            }

            List(collections) { collection in
                HStack {
                    Text(collection.name)
                        .fontWeight(collection.id == selectedCollection?.id ? .bold : .regular)
                    Spacer()
                    if collection.name != "Mi biblioteca" {
                        Button(action: {
                            selectedCollection = collection
                        }) {
                            Image(systemName: "folder.fill")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if collection.name == "Mi biblioteca" {
                        selectedCollection = nil
                    } else {
                        selectedCollection = collection
                    }
                }
            }

            Divider().padding(.vertical, 4)

            HStack {
                Text("Explorar carpeta")
                    .font(.headline)
                Spacer()
                Button(action: selectFolder) {
                    Image(systemName: "folder")
                }
            }
            .padding(.horizontal)

            List(folderPDFs) { pdf in
                Text(pdf.fileName)
                    .onTapGesture {
                        selectedPDF = pdf
                        isFromLibrary = false
                        if let doc = PDFDocument(url: pdf.url) {
                            editableMetadata = doc.metadata
                        }
                    }
            }
        }
        .frame(minWidth: 250)
    }
}
