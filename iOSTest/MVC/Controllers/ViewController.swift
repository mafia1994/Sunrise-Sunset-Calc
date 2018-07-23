//
//  ViewController.swift
//  iOSTest
//
//  Created by Pranav Chhikara on 23/07/18.
//  Copyright © 2018 Pranav Chhikara. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift
import NotificationCenter

class ViewController: UIViewController {

    @IBOutlet weak var sunSetLabel: UILabel!
    @IBOutlet weak var sunRiseLabel: UILabel!
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var tblViewLocations: UITableView!
    @IBOutlet weak var tblViewHeightConstraint: NSLayoutConstraint!
    
    let locationManager = CLLocationManager()
    var centerAnnotation:MKPointAnnotation!
    var selectedDate:Date!
    var locationList:[String] = []
    var coordinateDict:[String:CLLocationCoordinate2D] = [:]
    var searchTimer:Timer = Timer()
    var currentLocationName:String = ""
    var currentLocation:CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        prepareView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapSetNotification(_ sender: UIButton) {
        let alert = UIAlertController(title: "Attention!", message: "Do you want to set a notification for the Golden Hour of this location?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "YES", style: .default, handler: { action in
            self.setGoldenHourNotification()
        })
        let noAction = UIAlertAction(title: "NO", style: .cancel, handler: nil)
        alert.addAction(noAction)
        alert.addAction(yesAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didTapPinLoc(_ sender: UIButton) {
        let locationItem = LocationItem()
        locationItem.locationName = currentLocationName
        locationItem.latitude = myMap.centerCoordinate.latitude
        locationItem.longitude = myMap.centerCoordinate.longitude
        let realm = try! Realm()
        
        let predicate = NSPredicate(format: "locationName == %@", currentLocationName)
        let existingEntries = realm.objects(LocationItem.self).filter(predicate)
        if existingEntries.count > 0 {
            NSLog("Location already stored")
        } else {
            try! realm.write {
                realm.add(locationItem)
            }
        }
    }
    
    @IBAction func didTapSavedLoc(_ sender: UIButton) {
        let savedVC = SavedLocationsVC()
        savedVC.delegate = self
        self.present(savedVC, animated: true, completion: nil)
    }
    
    @IBAction func didPickNewDate(_ sender: UIDatePicker) {
        selectedDate = sender.date
        let sunRiseTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: true)
        let sunSetTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: false)
        sunRiseLabel.text = sunRiseTime
        sunSetLabel.text = sunSetTime
    }
    
    @IBAction func didTapPrevDate(_ sender: UIButton) {
        datePicker.date = Calendar.current.date(byAdding: .day, value: -1, to: datePicker.date)!
        selectedDate = datePicker.date
        let sunRiseTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: true)
        let sunSetTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: false)
        sunRiseLabel.text = sunRiseTime
        sunSetLabel.text = sunSetTime
    }
    
    @IBAction func didTapCurrentDate(_ sender: UIButton) {
        datePicker.date = Date()
        selectedDate = datePicker.date
        let sunRiseTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: true)
        let sunSetTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: false)
        sunRiseLabel.text = sunRiseTime
        sunSetLabel.text = sunSetTime
    }
    
    @IBAction func didTapNextDate(_ sender: UIButton) {
        datePicker.date = Calendar.current.date(byAdding: .day, value: 1, to: datePicker.date)!
        selectedDate = datePicker.date
        let sunRiseTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: true)
        let sunSetTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: false)
        
        sunRiseLabel.text = sunRiseTime
        sunSetLabel.text = sunSetTime
    }
    
    func prepareView() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in

        })
        
        let nib = UINib(nibName: "LocationItemCell", bundle: nil)
        tblViewLocations.register(nib, forCellReuseIdentifier: "locationCell")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        centerAnnotation = MKPointAnnotation()
        centerAnnotation.coordinate = myMap.centerCoordinate
        myMap.addAnnotation(centerAnnotation)
        selectedDate = Date()
    }
    
    func setGoldenHourNotification() {
        let sunSetTime = Utilities.sunTiming(forVariables: selectedDate, latitude: currentLocation.latitude, longitude: currentLocation.longitude, isRisingTime: false)
        let timeComponents = sunSetTime.split(separator: ":")
        var hour = Int(timeComponents[0])
        var minute = Int(timeComponents[1])
        
        if minute! < 30 {
            let diff = 30 - minute!
            minute = 60 - diff
            hour = hour! - 1
        } else {
            minute = minute! - 30
        }
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour!
        dateComponents.minute = minute!
        dateComponents.day = 7
        
        let content = UNMutableNotificationContent()
        content.title = "Golden Hour!!"
        content.body = "Bring out your cameras and start clicking!"
        content.badge = 1

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "GoldenHour", content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if let theError = error {
                NSLog("Error!")
            }
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        myMap.setRegion(coordinateRegion, animated: true)
        self.currentLocation = location.coordinate
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("\(locations)")
        self.centerMapOnLocation(location: locations.first!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Error")
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        searchBar.resignFirstResponder()
        
        let coordinates = mapView.centerCoordinate
        centerAnnotation.coordinate = coordinates
        
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if error == nil {
                if let placemark = placemarks?[0] {
                    if let place = placemark.locality {
                        self.currentLocationName = place
                    } else if let place = placemark.administrativeArea {
                        self.currentLocationName = place
                    }
                    
                } else {
                    NSLog("Error!")
                }
            } else {
                NSLog("Error!")
            }
        })
        self.currentLocation = location.coordinate
        let sunRiseTime = Utilities.sunTiming(forVariables: selectedDate, latitude: coordinates.latitude, longitude: coordinates.longitude, isRisingTime: true)
        let sunSetTime = Utilities.sunTiming(forVariables: selectedDate, latitude: coordinates.latitude, longitude: coordinates.longitude, isRisingTime: false)
        sunRiseLabel.text = sunRiseTime
        sunSetLabel.text = sunSetTime
    }
}

extension ViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText == "") {
            locationList.removeAll()
            tblViewLocations.reloadData()
            searchBar.resignFirstResponder()
        } else {
            if (searchTimer.isValid) {
                searchTimer.invalidate()
            }
            searchTimer = Timer(timeInterval: 1.0, repeats: false, block: {_ in
                self.searchForText(searchText: searchText)
            })
            RunLoop.current.add(searchTimer, forMode: .defaultRunLoopMode)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchForText(searchText: searchBar.text!)
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchForText(searchText: String) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchText
        request.region = myMap.region
        let localSearch = MKLocalSearch(request: request)
        localSearch.start(completionHandler: { (response, error) in
            if (error == nil) {
                if !self.searchBar.isFirstResponder {
                    return
                }
                if let result = response {
                    self.locationList.removeAll()
                    self.coordinateDict.removeAll()
                    for mapItem in result.mapItems {
                        self.locationList.append(mapItem.placemark.title!)
                        self.coordinateDict[mapItem.placemark.title!] = mapItem.placemark.coordinate
                    }
                    self.tblViewLocations.reloadData()
                } else {
                    NSLog("Something went wrong!")
                }
            } else {
                NSLog("Error!")
            }
        })
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tblViewHeightConstraint.constant = CGFloat(locationList.count*40)
        return locationList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath) as! LocationItemCell
        cell.locationLabel.text = locationList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let locationName = locationList[indexPath.row]
        let coordinates = coordinateDict[locationName]
        let location = CLLocation(latitude: (coordinates?.latitude)!, longitude: (coordinates?.longitude)!)
        self.centerMapOnLocation(location: location)
        
        locationList.removeAll()
        tblViewLocations.reloadData()
        searchBar.resignFirstResponder()
    }
    
}

extension ViewController:SavedLocationsVCDelegate {
    func didSelectLocationItem(locationItem: LocationItem) {
        let location = CLLocation(latitude: locationItem.latitude, longitude: locationItem.longitude)
        self.centerMapOnLocation(location: location)
    }
}

