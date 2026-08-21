//
//  SwitchStyle.swift
//  iPlayMusic
//
//  Created by Shiv on 12/07/26.
//

import SwiftUI

struct SwitchStyle: ToggleStyle {
    let onColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0) {
            configuration.label
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: .infinity)
                    .fill(configuration.isOn ? onColor : Color.gray.opacity(0.4))
                    .frame(width: 36, height: 16)
                RoundedRectangle(cornerRadius: .infinity)
                    .fill(Color.white)
                    .frame(width: 20, height: 14)
                    .padding(2)
            }
            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}
