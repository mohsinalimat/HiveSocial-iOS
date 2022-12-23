//
//  HIVEProducts.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/25/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import StoreKit

public struct HIVEProducts {
  
    public static let PlaylistTwo = "org.hiveinc.TheHive.playlistSlotTwo"
    public static let PlaylistThree = "org.hiveinc.TheHive.playlistSlotThree"
    public static let PlaylistFour = "org.hiveinc.TheHive.playlistSlotFour"
  
    private static let productIdentifiers: Set<ProductIdentifier> = [
        HIVEProducts.PlaylistTwo,
        HIVEProducts.PlaylistThree,
        HIVEProducts.PlaylistFour
    ]
    
    public static let store = IAPHelper(productIds: HIVEProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
