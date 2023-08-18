//
//  SheetView.swift
//  LivePolls
//
//  Created by Marcus Buexenstein on 2023/08/17.
//

import SwiftUI

struct SheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var manager: LivePollsManager
    
    @State private var poll = Poll()
    @State private var optionName = ""
    
    var body: some View {
        ZStack {
            VStack {
                Form {
                    createPollSection
                    addOptionSection
                    selectedOptionsSection
                }
                
                submitButton
            }
            
            if manager.inProgress {
                ProgressView()
            }
        }
        .navigationTitle("Create A Poll")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            closeToolbarItem
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
    
    var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
    var createPollSection: some View {
        Section {
            TextField("Enter a poll name", text: $poll.name , axis: .vertical)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if case .inProgress = manager.viewState {
                ProgressView()
            }
        } footer: {
            Text("Enter a poll name and add 2-10 options")
        }
    }
    
    var addOptionSection: some View {
        Section {
            TextField("Enter option name", text: $optionName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            HStack {
                Button {
                    withAnimation {
                        poll.options.append(.init(name: optionName, pollId: poll.id))
                    }
                    optionName = ""
                } label: {
                    Text("+ Add Option")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(addOptionIsDisabled)
            }
        } header: {
            HStack {
                Text("Options")
                
                Spacer()
                
                Text("(\(poll.options.count))")
            }
        }
    }
    
    var selectedOptionsSection: some View {
        Section {
            ForEach(poll.options) { option in
                Text(option.name)
            }
            .onDelete{ indexSet in
                poll.options.remove(atOffsets: indexSet)
            }
        } footer: {
            if !poll.options.isEmpty {
                Text("Swipe to remove")
            }
        }
    }
    
    var submitIsDisabled: Bool {
        poll.name.isEmpty || poll.options.count < 2 || manager.inProgress
    }
    
    var addOptionIsDisabled: Bool {
        optionName.isEmpty || poll.options.count >= 10 || manager.inProgress
    }
    
    var submitButton: some View {
        Button {
            Task {
                await manager.createPoll(poll)
                
                dismiss()
            }
        } label: {
            Text("Submit")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .disabled(submitIsDisabled)
    }
}

#Preview {
    NavigationStack {
        SheetView(manager: LivePollsManager())
    }
}
