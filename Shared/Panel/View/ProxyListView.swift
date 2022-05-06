import SwiftUI

struct ProxyListView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var controller: VPNController
    @EnvironmentObject private var viewModel: ProviderViewModel
    
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 3
    )
    
    var body: some View {
#if os(macOS)
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Text("关闭")
                }
                Spacer()
            }
            .foregroundColor(.accentColor)
            .buttonStyle(.plain)
            .padding()
            
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: columns) {
                    ForEach(viewModel.proxies, id: \.name) { model in
                        ProxyView(selected: $viewModel.selected)
                            .environmentObject(model)
                            .onTapGesture {
                                viewModel.select(controller: controller, proxy: model.name)
                            }
                    }
                }
                .padding()
            }
        }
        .frame(width: 540, height: 480)
#else
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("名称")
                        Spacer()
                        Text(viewModel.name)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("类型")
                        Spacer()
                        Text(viewModel.type.uppercased())
                            .foregroundColor(.secondary)
                    }
                }
                Section("包含") {
                    Picker(viewModel.name, selection: $viewModel.selected) {
                        ForEach(viewModel.proxies, id: \.name) { model in
                            ProxyView(selected: $viewModel.selected)
                                .environmentObject(model)
                        }
                    }
                    .onChange(of: viewModel.selected) { newValue in
                        viewModel.select(controller: controller, proxy: newValue)
                    }
                    .labelsHidden()
                    .pickerStyle(InlinePickerStyle())
                    .disabled(!viewModel.isSelectEnable)
                }
            }
            .navigationTitle(viewModel.name)
            .navigationBarTitleDisplayMode(.inline)
        }
#endif
    }
}