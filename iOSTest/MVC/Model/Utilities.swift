//
//  Utilities.swift
//  iOSTest
//
//  Created by Pranav Chhikara on 23/07/18.
//  Copyright © 2018 Pranav Chhikara. All rights reserved.
//

import UIKit
import MapKit
import LatLongToTimezone

class Utilities: NSObject {
    
    class func sunTiming(forVariables date:Date, latitude:Double, longitude:Double, isRisingTime:Bool) -> String {
        var sunTime = ""
        let zenith:Double = 90 * Double.pi/180
        
        let calendar = Calendar.current
        let year = Double(calendar.component(.year, from: date))
        let month = Double(calendar.component(.month, from: date))
        let day = Double(calendar.component(.day, from: date))
        
        //1. first calculate the day of the year
        let N1 = floor(275*month/9)
        let N2 = floor((month + 9) / 12)
        let N3 = (1 + floor((year - 4 * floor(year / 4) + 2) / 3))
        let N = N1 - (N2 * N3) + day - 30
        
        //2. convert the longitude to hour value and calculate an approximate time
        let lngHour = longitude / 15
        var const:Double
        if (isRisingTime) {
            const = 6
        } else {
            const = 18
        }
        let t = N + ((const - lngHour) / 24)
        
        //3. calculate the Sun's mean anomaly
        let M = (0.9856 * t) - 3.289
        
        //4. calculate the Sun's true longitude
        var L = M + (1.916 * sin(M * Double.pi/180)) + (0.020 * sin(2 * M * Double.pi/180)) + 282.634
        if (L < 0) {
            L += 360
        } else if (L > 360) {
            L -= 360
        }
        
        //5a. calculate the Sun's right ascension
        var RA = atan(0.91764 * tan(L * Double.pi/180)) * 180/Double.pi
        if (RA < 0) {
            RA += 360
        } else if (RA >= 360) {
            RA -= 360
        }
        //5b. right ascension value needs to be in the same quadrant as L
        let Lquadrant  = (floor( L/90)) * 90
        let RAquadrant = (floor(RA/90)) * 90
        RA = RA + (Lquadrant - RAquadrant)
        //5c. right ascension value needs to be converted into hours
        RA = RA / 15
        
        //6. calculate the Sun's declination
        let sinDec = 0.39782 * sin(L * Double.pi/180)
        let cosDec = cos(asin(sinDec))
        
        //7a. calculate the Sun's local hour angle
        let cosH = (cos(zenith) - (sinDec * sin(latitude * Double.pi/180))) / (cosDec * cos(latitude * Double.pi/180))
        if (cosH > 1) {
            sunTime = "Sun does not rise for given data"
            return sunTime
        } else if (cosH < -1) {
            sunTime = "Sun does not set for given data"
            return sunTime
        }
        //7b. finish calculating H and convert into hours
        var H:Double
        if (isRisingTime) {
            H = 360 - (acos(cosH) * 180/Double.pi)
        } else {
            H = (acos(cosH) * 180/Double.pi)
        }
        H /= 15
        
        //8. calculate local mean time of rising/setting
        let T = H + RA - (0.06571 * t) - 6.622
        
        //9. adjust back to UTC
//        var UT = T - lngHour
        var UT = T
        if (UT < 0) {
            UT += 24
        } else if (UT >= 24) {
            UT -= 24
        }
        
        //10. convert UT value to local time zone of latitude/longitude
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let timeZone = TimezoneMapper.latLngToTimezone(location)
        let localOffset = Double((timeZone?.secondsFromGMT())!)
        let localT = UT + (localOffset / 3600)/24
        return hourToString(hour: localT)
    }
    
    private class func hourToString(hour:Double) -> String {
        let hours = Int(floor(hour))
        let mins = Int(floor(hour * 60).truncatingRemainder(dividingBy: 60))
        let secs = Int(floor(hour * 3600).truncatingRemainder(dividingBy: 60))
        
        return String(format:"%d:%02d:%02d", hours, mins, secs)
    }

}
