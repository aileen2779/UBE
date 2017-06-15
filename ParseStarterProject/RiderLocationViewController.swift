//
//  RiderLocationViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Rob Percival on 11/07/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

class RiderLocationViewController: UIViewController, MKMapViewDelegate {

    var requestLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var requestUsername = ""
    
    @IBOutlet var map: MKMapView!
    
    @IBAction func acceptRequest(_ sender: AnyObject) {
        
        let query = PFQuery(className: "RiderRequest")
        
        query.whereKey("username", equalTo: requestUsername)
        
        query.findObjectsInBackground { (objects, error) in
            
            if let riderRequests = objects {
                
                for riderRequest in riderRequests {
                    
                    riderRequest["driverResponded"] = PFUser.current()?.username
                    
                    riderRequest.saveInBackground()
                    
                    let requestCLLocation = CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)
                    
                    CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: { (placemarks, error) in
                        
                        if let placemarks = placemarks {
                            
                            if placemarks.count > 0 {
                                
                               let mKPlacemark = MKPlacemark(placemark: placemarks[0])
                                
                                let mapItem = MKMapItem(placemark: mKPlacemark)
                                
                                mapItem.name = self.requestUsername
                                
                                let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                                
                                mapItem.openInMaps(launchOptions: launchOptions)
                                
                            }
                            
                        }
                        
                        
                    })
                    
                }
                
            }
            
            
        }
        
    }
    
    
    @IBOutlet var acceptRequestButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        map.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = requestLocation
        
        annotation.title = requestUsername
        
        map.addAnnotation(annotation)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
