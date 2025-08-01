//
//  BlockAppPicker.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 01/08/2025.
//
import SwiftUI
import FamilyControls

struct BlockAppPicker: View {
    @StateObject var model = AppSelectionModel()
    @State private var isPresented = false

    var body: some View {
        Button("Select Apps to Discourage") { isPresented = true }
            .familyActivityPicker(isPresented: $isPresented,
                                  selection: $model.selectionToDiscourage)
            .onChange(of: isPresented) { _, showing in
                if showing == false { model.apply() }    // iOS 17+ onChange
            }
    }
}

