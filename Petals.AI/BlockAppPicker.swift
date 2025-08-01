//
//  BlockAppPicker.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 01/08/2025.
//
import SwiftUI
import FamilyControls

struct BlockAppPicker: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var model = AppSelectionModel()
    @State private var isPresented: Bool = false
    var body: some View {
        Button("Select Apps to Discourage"){
            isPresented = true
        }
        .familyActivityPicker(isPresented: $isPresented, selection: $model.selectionToDiscourage)
    }
}

