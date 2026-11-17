//
//  ZiplineApp.swift
//  Zipline
//
//  Created by Amirali Yazdani.
//
import SwiftUI

@main
struct ZiplineApp: App {
    var body: some Scene {
        WindowGroup {
            ZiplineHomeView(modernExperience: true)
                .tint(ZiplineStyle.accent)
        }
    }
}