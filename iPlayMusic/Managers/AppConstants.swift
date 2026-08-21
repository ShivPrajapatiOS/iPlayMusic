//
//  AppConstants.swift
//  iPlayMusic
//
//  Created by Shiv on 31/07/26.
//

import Foundation
import Combine
import SwiftUI

struct AppConstants {
    // 0. Purchase Plan Identifier
    static let YEARLY_ID = "com.iplay.music.yearly"
    static let MONTHLY_ID = "com.iplay.music.monthly"
    static let SHARED_SECRET_KEY = "cde2cbf2ff1041d885dce7e8aceb5103"
    
    // 1. App Group Identifier
    static let appGroupID = "group.com.iplay.musicapp"
    static let keychainGroupID = "group.com.iplay.musicapp"
    
    // 2. App Info URLs
    static let privacyPolicyLink = "https://iplay.com/privacy-policy/"
    static let termsOfServiceLink = "https://iplay.com/terms-of-use/"
    static let feedbackSupportMail = "contact.iplay@gmail.com"
}

extension UserDefaults {
    static var shared: UserDefaults? {
        return UserDefaults(suiteName: AppConstants.appGroupID)
    }
    
    class var yearlyPrice: String {
        get { return UserDefaults.standard.string(forKey: "yearlyPrice") ?? "$29.99" }
        set { UserDefaults.standard.setValue(newValue,forKey: "yearlyPrice") }
    }
    
    class var yearlyPerMonthPrice: String {
        get { return UserDefaults.standard.string(forKey: "yearlyPerMonthPrice") ?? "$2.49" }
        set { UserDefaults.standard.setValue(newValue,forKey: "yearlyPerMonthPrice") }
    }
    
    class var monthlyPrice: String {
        get { return UserDefaults.standard.string(forKey: "monthlyPrice") ?? "$4.99" }
        set { UserDefaults.standard.setValue(newValue,forKey: "monthlyPrice") }
    }
    
    class var yearlyDiscountPercentage: Int {
        get { return UserDefaults.standard.integer(forKey: "yearlyDiscountPercentage") }
        set { UserDefaults.standard.setValue(newValue,forKey: "yearlyDiscountPercentage") }
    }
    
    class var inReview: Bool {
        get { return UserDefaults.standard.bool(forKey: "inReview") }
        set { UserDefaults.standard.setValue(newValue,forKey: "inReview") }
    }
    
    class var closeDelay: Int {
        get { return UserDefaults.standard.integer(forKey: "closeDelay") }
        set { UserDefaults.standard.setValue(newValue,forKey: "closeDelay") }
    }
}
