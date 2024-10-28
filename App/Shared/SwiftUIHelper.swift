//
//  SwiftUIHelper.swift
//  App
//
//  Created by Jorge Flores on 10/23/24.
//

import SwiftUI

#if os(macOS)
typealias EditButton = EmptyView
typealias TripForm = List
typealias TripGroupBox = GroupBox
#else
typealias CustomerForm = Form
typealias CustomerGroupBox = Group
#endif

extension Color {
    static var tripGray: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color.gray
        #endif
    }
}

@MainActor
extension ToolbarItemPlacement {
    #if os(macOS)
    static let topBarLeading = automatic
    static let topBarTrailing = automatic
    static let bottomBar = automatic
    #endif
}

/**
 Layout constants.
 */
struct LayoutConstants {
    static let sheetIdealWidth = 400.0
    static let sheetIdealHeight = 500.0
}

