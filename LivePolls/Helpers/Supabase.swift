//
//  Supabase.swift
//  LivePolls
//
//  Created by Marcus Buexenstein on 2023/08/16.
//

import Foundation
import Supabase

fileprivate enum Constants {
    static let supabaseURL = URL(string: "SUPABASE_URL")!
    static let supabaseKey = "SUPABASE_ANON_KEY"
}

class Supabase {
    let client: SupabaseClient
    
    static let shared = Supabase()
    
    init() {
        client = SupabaseClient(
            supabaseURL: Constants.supabaseURL,
            supabaseKey: Constants.supabaseKey
        )
    }
}
