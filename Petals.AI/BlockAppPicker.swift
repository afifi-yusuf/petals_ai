//
//  BlockAppPicker.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 01/08/2025.
//
import SwiftUI
import FamilyControls

struct BlockAppPicker: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var model = AppSelectionModel()
    @State private var isPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack {
                    Button("Select Apps to Discourage") { isPresented = true }
                        .familyActivityPicker(isPresented: $isPresented,
                                              selection: $model.selectionToDiscourage)
                        .onChange(of: isPresented) { _, showing in
                            if showing == false { model.apply() }
                        }
                }
                .padding()
            }
            .navigationTitle("Discourage Apps")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
    }
}

