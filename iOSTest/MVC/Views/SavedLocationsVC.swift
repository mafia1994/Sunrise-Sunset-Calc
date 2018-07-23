//
//  SavedLocationsVC.swift
//  iOSTest
//
//  Created by Pranav Chhikara on 23/07/18.
//  Copyright © 2018 Pranav Chhikara. All rights reserved.
//

import UIKit
import RealmSwift

class SavedLocationsVC: UIViewController {

    @IBOutlet weak var tblViewLocations: UITableView!
    @IBOutlet weak var tblViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate:SavedLocationsVCDelegate?
    var locationList:[LocationItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        prepareView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareView() {
        let nib = UINib(nibName: "LocationItemCell", bundle: nil)
        tblViewLocations.register(nib, forCellReuseIdentifier: "locationCell")
        
        let realm = try! Realm()
        let locationItems = realm.objects(LocationItem.self)
        for item in locationItems {
            locationList.append(item)
        }
        tblViewLocations.reloadData()
    }
    
    @IBAction func didTapBkgButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

protocol SavedLocationsVCDelegate:class {
    func didSelectLocationItem(locationItem: LocationItem)
}

extension SavedLocationsVC: UITableViewDelegate, UITableViewDataSource {
    
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
        let locationItem = locationList[indexPath.row]
        cell.locationLabel.text = locationItem.locationName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectLocationItem(locationItem: locationList[indexPath.row])
        self.dismiss(animated: true, completion: nil)
    }
}
