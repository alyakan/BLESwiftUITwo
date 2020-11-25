//
//  ContentView.swift
//  BLESwiftUITwo
//
//  Created by Aly Yakan on 23/11/2020.
//

import SwiftUI
import Combine

let testBleServer = BLEServer(services: [.test])
let screenBounds = UIScreen.main.bounds

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel = ContentViewModel()

    @State private var valueToWrite = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Main VStack
                VStack(alignment: .leading, spacing: 30) {
                    Divider() // Push-out view, expands the VStack.
                    Text("Connection: \(String(describing: self.viewModel.connectionState))")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.connectionState != .poweredOn {
                        Button("Start bluetooth", action: viewModel.start)
                            .padding(.horizontal)
                    }

                    Divider()

                    Text(viewModel.connectedPeripheral == nil ? "Peripherals" : "Current Peripheral")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.connectedPeripheral == nil {
                        ScrollView {
                            LazyVStack {
                                ForEach(viewModel.peripherals, id: \.id) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .center) {
                                            Text("Name: \(item.name ?? "N/A")")
                                                .fontWeight(.medium)
                                                .font(.subheadline)
                                            Spacer()
                                            Text("rssi: \(item.rssi ?? -10000)")
                                                .font(.footnote)
                                        }

                                        Text("ID: \(item.id)")
                                            .font(.caption)
                                            .foregroundColor(Color(.secondaryLabel))

                                        Text("Connection: \(String(describing: item.state))")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        viewModel.connect(peripheral: item)
                                    }
                                }
                            }
                        }
                    } else if let item = viewModel.connectedPeripheral {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .center) {
                                Text("Name: \(item.name ?? "N/A")")
                                    .fontWeight(.medium)
                                    .font(.subheadline)
                                Spacer()
                                Text("rssi: \(item.rssi ?? -10000)")
                                    .font(.footnote)
                            }

                            Text("ID: \(item.id)")
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))

                            Text("Connection: \(String(describing: item.state))")
                                .font(.caption)

                            Divider()

                            VStack(alignment: .leading) {
                                Text("Readable Characteristic: \(viewModel.rCharValue)")
                                    .font(.subheadline)
                                Text("Writable Characteristic: \(viewModel.wCharValue)")
                                    .font(.subheadline)
                                HStack(spacing: 20) {
                                    Text("Notify Characteristic:")

                                    colorFrom(string: viewModel.nCharValue)
                                        .frame(width: 12, height: 12)
                                        .clipShape(Circle())
                                }

                                TextField("", text: $valueToWrite)
                                Button("Write value") {
                                    viewModel.writeOutValue(valueToWrite)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .navigationTitle(Text("HomeCharging"))

                // Loading View
                if viewModel.loading {
                    ZStack {
                        BlurView(style: .systemMaterial)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text("Loading...")
                    }
                }
            }
        }
    }

    func colorFrom(string: String) -> Color {
        switch string {
        case "red": return Color.red
        case "blue": return Color.blue
        case "orange": return Color.orange
        case "grey": return Color.gray
        default: return Color.green
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
