//
//  ZiplineClassicApp.swift
//  Zipline
//
//  Created by Amirali Yazdani.
//
import SwiftUI

@main
struct ZiplineClassicApp: App {
    var body: some Scene {
        WindowGroup {
            ZiplineHomeView(modernExperience: false)
                .tint(ZiplineStyle.accent)
        }
    }
}