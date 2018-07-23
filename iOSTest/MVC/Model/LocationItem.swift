//
//  LocationItem.swift
//  iOSTest
//
//  Created by Pranav Chhikara on 23/07/18.
//  Copyright © 2018 Pranav Chhikara. All rights reserved.
//

import UIKit
import RealmSwift

class LocationItem: Object {
    @objc dynamic var locationName: String = ""
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    
}
