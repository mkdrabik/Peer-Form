//
//  LoadingView.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/13/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color("babyblue")
            VStack{

                Image("Logo")
                    .resizable()
                    .frame(width: 300, height: 300)
            }
        }
        .ignoresSafeArea(edges: .all)
    }
}

#Preview {
    LoadingView()
}
