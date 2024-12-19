//
//  SetUpVoew.swift
//  bluetoothChat
//
//  Created by Kasper Munch on 26/08/2021.
//

import SwiftUI

/**
 SetUpView handles all initial first logins where users choose a username
 and are then redirected to ContentView which is the main View of the app.
 */
struct SetupView: View {
    @State private var isLoggedIn = false
    
    var body: some View {
        if isLoggedIn {
            HomeView()
        } else {
            LoginView()
        }
    }
}

