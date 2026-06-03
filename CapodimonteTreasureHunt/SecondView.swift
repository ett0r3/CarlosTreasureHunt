//
//  SecondView.swift
//  CapodimonteTreasureHunt
//
//  Created by AFP FED 02 on 02/06/26.
//

import SwiftUI

struct SecondView: View {

    var body: some View {
        OnboardingView()
    }
}

struct SecondView_Previews: PreviewProvider {
    static var previews: some View {
        SecondView()
            .environmentObject(GameStore())
    }
}
