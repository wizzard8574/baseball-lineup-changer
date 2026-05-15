// Created by Rich Morris on 5/5/26.
// Lineup Changer
// MainTab.swift
//
//
//
// App-level tab identity for the main interface.
import Foundation

// MARK: - Main Tab Model
// Tabs available in the main app interface.
// Hashable conformance allows these cases to be used as TabView selection tags.
enum MainTab: Hashable {
    case field
    case lineup
    case players
    case notes
    case settings
}
