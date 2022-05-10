import SwiftUI

struct ConfigListView: View {
    
    @StateObject private var viewModel = ConfigListViewModel()
    
    @AppStorage(Clash.currentConfigUUID, store: .shared) private var uuidString: String = ""
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClashConfig.date, ascending: false)],
        animation: .default
    ) private var configs: FetchedResults<ClashConfig>
    
#if os(macOS)
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 3
    )
#endif
    
    var body: some View {
        buildBody()
            .fileImporter(isPresented: $viewModel.importLocalFile, allowedContentTypes: [.yaml]) { result in
                switch result {
                case .success(let url):
                    viewModel.onImportLocalFile(url: url, context: context)
                case .failure(let error):
                    debugPrint(error.localizedDescription)
                }
            }
            .sheet(isPresented: $viewModel.downloadRemoteFile) {
                FileDownloadView { url in
                    viewModel.onImportRemoteFile(url: url, context: context)
                }
            }
            .sheet(item: $viewModel.renamedConfig) { config in
                ConfigRenameView(name: config.name ?? "") { new in
                    viewModel.onRename(config: config, newName: new, context: context)
                }
            }
    }
    
    private func buildBody() -> some View {
#if os(macOS)
        VStack(spacing: 0) {
            HStack {
                Button("关闭") { dismiss() }
                Spacer()
                ImportButton(importLocalFile: $viewModel.importLocalFile, downloadRemoteFile: $viewModel.downloadRemoteFile)
            }
            .foregroundColor(.accentColor)
            .buttonStyle(.plain)
            .padding()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns) {
                    ForEach(configs) { config in
                        GroupBox {
                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        HStack(alignment: .top, spacing: 0) {
                                            Text(config.name ?? "")
                                            Text("\n")
                                            Spacer()
                                            if let uuid = config.uuid,  uuidString == uuid.uuidString {
                                                Circle()
                                                    .frame(width: 12, height: 12)
                                                    .foregroundColor(.green)
                                                    .padding(EdgeInsets(top: 2, leading: 8, bottom: 0, trailing: 0))
                                            }
                                        }
                                        .lineLimit(2)
                                    }
                                    HStack {
                                        Spacer()
                                        
                                        Button(role: .destructive) {
                                            print("更新")
                                        } label: {
                                            Image(systemName: "goforward")
                                                .foregroundColor(.accentColor)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button(role: .destructive) {
                                            viewModel.onDelete(config: config, context: context)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Menu {
                                            Button(role: nil) {
                                                viewModel.renamedConfig = config
                                            } label: {
                                                Text("重命名")
                                            }
                                            Divider()
                                            Button(role: nil) {
                                                viewModel.onShare(config: config)
                                            } label: {
                                                Text("导出")
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis.circle")
                                        }
                                        .menuStyle(.borderlessButton)
                                        .menuIndicator(.hidden)
                                        .fixedSize()
                                        .offset(x: 4, y: 0)
                                    }
                                }
                                .lineLimit(1)
                                Spacer()
                            }
                            .padding(8)
                        }
                        .onTapGesture {
                            viewModel.onSelected(config: config)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .fileExporter(isPresented: viewModel.isFileExporterPresented, document: YAMLFile(exportItems: viewModel.exportItems), contentType: .yaml, defaultFilename: "Config.yml") { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    debugPrint(error.localizedDescription)
                }
            }
        }
        .frame(width: 540, height: 480)
#else
        NavigationView {
            List(configs) { config in
                HStack {
                    Text(config.name ?? "-")
                    Spacer()
                    Text(Image(systemName: "checkmark"))
                        .fontWeight(.medium)
                        .foregroundColor(config.uuid.flatMap({ $0.uuidString }) == uuidString ? .accentColor : .clear)
                }
                .lineLimit(1)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.onSelected(config: config)
                    dismiss()
                }
                .contextMenu {
                    Button(role: nil) {
                        viewModel.renamedConfig = config
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }
                    Button(role: nil) {
                        viewModel.onShare(config: config)
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        viewModel.onDelete(config: config, context: context)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
            .navigationBarTitle("配置管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ImportButton(importLocalFile: $viewModel.importLocalFile, downloadRemoteFile: $viewModel.downloadRemoteFile)
                }
            }
            .activitySheet(items: $viewModel.exportItems)
        }
#endif
    }
}
