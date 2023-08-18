//
//  LivePollsManager.swift
//  LivePolls
//
//  Created by Marcus Buexenstein on 2023/08/16.
//

import SwiftUI
import Observation
import Realtime

@Observable
final class LivePollsManager {
    enum ViewState {
        case inProgress, success, failed(Error)
    }
    
    private enum DatabaseTables: String {
        case polls, options
    }
    
    private let supabase = Supabase.shared
    private let client: RealtimeClient
    private var pollChannel: Channel
    private var optionChannel: Channel
    private var table: DatabaseTables = .polls
    
    var errorMessage = ""
    var errorIsPresented = false
    
    private(set) var viewState: ViewState = .inProgress {
        didSet {
            if case .failed(let error) = viewState {
                errorMessage = error.localizedDescription
                errorIsPresented.toggle()
                viewState = .success
            }
        }
    }
    
    var polls = [Poll]()
    var inProgress: Bool {
        if case .inProgress = viewState {
            return true
        } else {
            return false
        }
    }
    
    init(isLogging: Bool = false) {
        self.client = supabase.client.realtime
        
        self.pollChannel = client.channel(.table("polls", schema: "public"))
        self.optionChannel = client.channel(.table("options", schema: "public"))
        
        Task {
            await initFetch()
            
            listenToLivePolls()
        }
        
        if isLogging {
            logger()
        }
    }
    
    @MainActor
    private func initFetch() async {
        async let pollsTask: [Poll] = supabase.client.database.from("polls").execute().value
        async let optionsTask: [Option] = supabase.client.database.from("options").execute().value
        
        do {
            let (polls, options) = try await (pollsTask, optionsTask)
            
            withAnimation {
                self.polls = polls
            }
            
            mapOptionsToPoll(options)
            
            viewState = .success
        } catch {
            viewState = .failed(error)
            print(error.localizedDescription)
        }
    }
    
    func createPoll(_ poll: Poll) async {
        viewState = .inProgress
        defer { viewState = .success }
        
        do {
            // Insert Poll
            table = .polls
            try await supabase.client.database.from(table.rawValue).insert(values: poll).execute()
            // Insert Options
            table = .options
            try await supabase.client.database.from(table.rawValue).insert(values: poll.options).execute()
            viewState = .success
        } catch {
            viewState = .failed(error)
            print(error.localizedDescription)
        }
    }
    
    func incrementCount(_ id: UUID) async {
        viewState = .inProgress
        defer { viewState = .success }
        
        struct Params: Encodable {
            let id: UUID
        }
        
        do {
            try await supabase.client.database.rpc(fn: "increment_count", params: Params(id: id)).execute()
            
            viewState = .success
        } catch {
            viewState = .failed(error)
            print(error.localizedDescription)
        }
    }
    
    func refreshPolls() async {
        viewState = .inProgress
        await initFetch()
    }
    
    private func mapOptionsToPoll(_ options: [Option]) {
        options.forEach { option in
            let index = polls.firstIndex(where: { $0.id == option.pollId })
            
            if let index {
                polls[index].options.append(option)
            }
        }
    }
    
    private func listenToLivePolls() {
        pollChannel.on(.insert) { message in
            do {
                let poll = try Poll.init(dictionary: self.getDictionary(message))
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.polls.append(poll)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        pollChannel.on(.update) { message in
            do {
                let poll = try Poll.init(dictionary: self.getDictionary(message))
                
                DispatchQueue.main.async {
                    let index = self.polls.firstIndex(where: { $0.id == poll.id })
                    
                    if let index {
                        self.polls[index].lastUpdatedOptionId = poll.lastUpdatedOptionId
                        self.polls[index].updatedAt = poll.updatedAt
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        optionChannel.on(.insert) { message in
            do {
                let option = try Option.init(dictionary: self.getDictionary(message))
                
                DispatchQueue.main.async {
                    withAnimation {
                        let index = self.polls.firstIndex(where: { $0.id == option.pollId })
                        
                        if let index {
                            self.polls[index].options.append(option)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        optionChannel.on(.update) { message in
            do {
                let option = try Option.init(dictionary: self.getDictionary(message))
                
                DispatchQueue.main.async {
                    let pollIndex = self.polls.firstIndex(where: { $0.id == option.pollId })
                    
                    if let pollIndex {
                        let optionIndex = self.polls[pollIndex].options.firstIndex(where: {$0.id == option.id})
                        
                        if let optionIndex {
                            withAnimation {
                                self.polls[pollIndex].options[optionIndex] = option
                            }
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        self.pollChannel.subscribe()
        self.optionChannel.subscribe()
        
        self.connect()
    }
    
    private func getDictionary(_ message: Message) -> [String: Any] {
        guard let record = message.payload["record"] else { return [:] }
        
        let dictionary = record as? [String: Any]
        
        guard let dictionary else { return  [:] }
        
        return dictionary
    }
    
    private func logger() {
        client.delegateOnOpen(to: self) { (self) in
            print("Client Opend")
        }
        
        client.delegateOnClose(to: self) { (self) in
            print("Client Closed")
        }
        
        client.delegateOnError(to: self) { (self, error) in
            print("Client Errored. \(error)")
        }
        
        client.logger = { msg in print("LOG:", msg) }
    }
    
    func connect() {
        self.client.connect()
    }
    
    func disconnect() {
        pollChannel.unsubscribe()
        self.client.remove(pollChannel)
        
        optionChannel.unsubscribe()
        self.client.remove(optionChannel)
        
        self.client.disconnect()
    }
}
