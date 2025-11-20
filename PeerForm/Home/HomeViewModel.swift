//
//  HomeViewModel.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//
import Foundation
import Combine

enum HomeTab {
    case feed
    case camera
    case profile
    case friends
}

class HomeViewModel: ObservableObject {
    @Published var selectedTab: HomeTab = .feed
}

