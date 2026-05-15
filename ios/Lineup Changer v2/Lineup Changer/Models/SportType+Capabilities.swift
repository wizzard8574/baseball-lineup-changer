// Created by Rich Morris on 5/5/26.
// Lineup Changer
// SportType+Capabilities.swift
//
//
//
import Foundation

extension SportType {
    var isLaunchSelectable: Bool {
        self == .baseballSoftball
    }

    var showsBaseballSettings: Bool {
        self == .baseballSoftball
    }

    var showsBasketballSettings: Bool {
        self == .basketball
    }
}
