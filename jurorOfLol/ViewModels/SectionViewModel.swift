//
//  SectionViewModel.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/03.
//

import Foundation
import RxDataSources

struct Section {
    var title: String
    var items: [SettingsOptionType]
}
extension Section: SectionModelType {
    typealias Item = SettingsOptionType
    
    init(original: Section, items: [SettingsOptionType]) {
        self = original
        self.items = items
    }
}
enum SettingsOptionType {
    case staticCell(model: SettingsStaticOption)
    case switchCell(model: SettingsSwitchOption)
}

struct SettingsStaticOption {
    let title: String
    let handler: (() -> Void)
}

struct SettingsSwitchOption {
    let title: String
    let handler: (() -> Void)
    var isOn: Bool
}
