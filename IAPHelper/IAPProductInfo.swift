//
//  ProductInfo.swift
//  IAPHelper
//
//  Created by Russell Archer on 09/07/2020.
//

import UIKit

/// Holds localized product data returned by teh App Store
internal struct IAPProductInfo {
    var id: String
    var imageName: String
    var localizedTitle: String
    var localizedDescription: String
    var localizedPrice: String
    var purchased: Bool
}
