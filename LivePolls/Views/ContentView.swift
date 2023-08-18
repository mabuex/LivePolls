//
//  ContentView.swift
//  LivePolls
//
//  Created by Marcus Buexenstein on 2023/08/16.
//

import SwiftUI

struct ContentView: View {
    @Bindable private var manager = LivePollsManager()
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var sheetIsPresented = false
    @State private var isExpanded = true
    @State private var selectedPoll: Poll? = nil
    
    var body: some View {
        VStack {
            ZStack {
                if manager.polls.count == 0 {
                    Button("Create a Poll") {
                        sheetIsPresented.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.white)
                } else {
                    List {
                        livePollsSection
                    }
                    .refreshable {
                        Task {
                            await manager.refreshPolls()
                        }
                    }
                }
                
                if manager.inProgress {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Live Polls")
        .toolbar {
            addPollToolbarItem
        }
        .sheet(isPresented: $sheetIsPresented) {
            NavigationStack {
                SheetView(manager: manager)
            }
        }
        .navigationDestination(item: $selectedPoll) { poll in
            PollView(manager: manager, poll: poll)
        }
        .alert("Error", isPresented: $manager.errorIsPresented) {
            Button("Ok") {
                manager.errorMessage = ""
                manager.errorIsPresented.toggle()
            }
        } message: {
            Text(manager.errorMessage)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .inactive:
                manager.disconnect()
            case .background:
                manager.disconnect()
            case .active:
                manager.connect()
            @unknown default:
                manager.disconnect()
            }
        }
    }
    
    var addPollToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                sheetIsPresented.toggle()
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    var livePollsSection: some View {
        ForEach(manager.polls.sorted(by: { $0.updatedAt > $1.updatedAt })) { poll in
            Section {
                pollRow(poll: poll)
            } header: {
                Text("\(poll.name)")
            }
            .headerProminence(.increased)
        }
    }
    
    @ViewBuilder
    func pollRow(poll: Poll) -> some View {
        VStack {
            HStack(alignment: .top) {
                Image(systemName: "chart.bar.xaxis")
                Text(String(poll.totalCount))
                
                Spacer()
                
                Image(systemName: "clock.fill")
                Text(poll.updatedAt, style: .time)
            }
            
            Group {
                if poll.totalCount == 0 {
                    Button("No one voted yet. Be the first!") {
                        selectedPoll = poll
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.white)
                } else {
                    PollChart(options: poll.options)
                }
            }
            .frame(height: 160)
        }
        .onTapGesture {
            selectedPoll = poll
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
