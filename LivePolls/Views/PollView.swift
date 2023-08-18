//
//  PollView.swift
//  LivePolls
//
//  Created by Marcus Buexenstein on 2023/08/17.
//

import SwiftUI

struct PollView: View {
    @Bindable var manager: LivePollsManager
    @State var poll: Poll
    
    var body: some View {
        ZStack {
            List {
                mainSection
                
                pollChartSection
                
                voteSection
            }
            
            if manager.inProgress {
                ProgressView()
            }
        }
        .navigationTitle(poll.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: manager.polls) { _, newValue in
            let updatedPoll = newValue.first(where: { $0.id == poll.id } )
            if let updatedPoll {
                self.poll = updatedPoll
            }
        }
        .alert("Error", isPresented: $manager.errorIsPresented) {
            Button("Ok") {
                manager.errorMessage = ""
                manager.errorIsPresented.toggle()
            }
        } message: {
            Text(manager.errorMessage)
        }
    }
    
    var mainSection: some View {
        Section {
            HStack {
                Text("Updated at")
                
                Spacer()
              
                Text(poll.updatedAt, style: .time)
            }
            
            HStack {
                Text("Total Vote Count")
                Spacer()
                Text("\(poll.totalCount)")
            }
        }
    }
    
    var pollChartSection: some View {
        Section {
            PollChart(options: poll.options)
                .frame(height: 160)
        }
    }
    
    var voteSection: some View {
        Section("Vote") {
            ForEach(poll.options) { option in
                Button {
                    Task {
                        await manager.incrementCount(option.id)
                    }
                } label: {
                    HStack {
                        Text("+1")
                        Text(option.name)
                        Spacer()
                        Text("\(option.count)")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PollView(manager: LivePollsManager(), poll: Poll())
    }
}
