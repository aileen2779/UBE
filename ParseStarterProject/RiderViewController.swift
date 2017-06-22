//
//  RiderViewController.swift


import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    func displayAlert(title: String, message: String) {

        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertcontroller, animated: true, completion: nil)
        
    }
    
    var driverOnTheWay = false
    var locationManager = CLLocationManager()
    var riderRequestActive = true
    var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    @IBOutlet var mapView: MKMapView!
    @IBAction func callAnUber(_ sender: AnyObject) {
        
        if riderRequestActive {
            
            callAnUberButton.setTitle("Go ahead and schedule a ride", for: [])
            riderRequestActive = false
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                    
                    for riderRequest in riderRequests {
                            riderRequest.deleteInBackground()
                        
                    }
                }
            })
            
        } else {
        
        if userLocation.latitude != 0 && userLocation.longitude != 0 {
            
            riderRequestActive = true
            
            self.callAnUberButton.setTitle("Cancel Uber", for: [])
        
            let riderRequest = PFObject(className: "RiderRequest")
            riderRequest["username"] = PFUser.current()?.username
            riderRequest["location"] = PFGeoPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
            riderRequest.saveInBackground(block: { (success, error) in
                
                if success {
                    print("Called an uber")
                } else {
                    
                    self.callAnUberButton.setTitle("Call An Uber", for: [])
                    self.riderRequestActive = false
                    self.displayAlert(title: "Could not call Uber", message: "Please try again!")
                }
            })
            
        } else {
            
            displayAlert(title: "Could not call Uber", message: "Cannot detect your location.")
            
        }
        
        }
        
    }
    
    @IBOutlet var callAnUberButton: UIButton!
    
/*
    @IBAction func whereToTextField(_ sender: CustomTextField) {

        if (!datePickerVisible) {
            showDatePicker()
        }
    }
    
    var datePickerVisible = false

    func showDatePicker() {
        datePickerVisible = true
        let datePickerView:UIDatePicker = UIDatePicker()
        
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        datePickerView.frame = CGRect(x: 0, y: 137, width: view.frame.width, height: 200)
        datePickerView.backgroundColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
        // Add an event to call onDidChangeDate function when value is changed.
        datePickerView.addTarget(self, action: #selector(RiderViewController.datePickerValueChanged(_:)), for: .valueChanged)
        
        // Add DataPicker to the view
        view.addSubview(datePickerView)
        
    }

    func datePickerValueChanged(_ sender: UIDatePicker){
        
        // Create date formatter
        let dateFormatter: DateFormatter = DateFormatter()
        
        // Set date format
        dateFormatter.dateFormat = "MM/dd/yyyy hh:mm a"
        
        // Apply date format
        let selectedDate: String = dateFormatter.string(from: sender.date)
        
        print("Selected value \(selectedDate)")
    }
*/
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        callAnUberButton.isHidden = true

        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: (PFUser.current()?.username)!)
        query.findObjectsInBackground(block: { (objects, error) in
            
            if let objects = objects {
                if objects.count > 0 {
                    self.riderRequestActive = true
                    self.callAnUberButton.setTitle("Cancel Uber", for: [])
                }
            }
            self.callAnUberButton.isHidden = false
        })

        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = manager.location?.coordinate {
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            if driverOnTheWay == false {
                
                let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.mapView.setRegion(region, animated: true)
                self.mapView.removeAnnotations(self.mapView.annotations)
                //let annotation = MKPointAnnotation()
                //annotation.coordinate = userLocation
                //annotation.title = "Your Location"
                //self.mapView.addAnnotation(annotation)
                
                
                self.mapView.showsUserLocation = true
            }
            
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                    for riderRequest in riderRequests {
                        riderRequest["location"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                        riderRequest.saveInBackground()
                    }
                }
            })

            
        }
        
        if riderRequestActive == true {
            
            let query = PFQuery(className: "RiderRequest")

            query.whereKey("username", equalTo: (PFUser.current()?.username!)!)
            query.findObjectsInBackground(block: { (objects, error) in
                
                if let riderRequests = objects {
                    for riderRequest in riderRequests {
                        if let driverUsername = riderRequest["driverResponded"] {

                            let query = PFQuery(className: "DriverLocation")
                            query.whereKey("username", equalTo: driverUsername)
                            query.findObjectsInBackground(block: { (objects, error) in
                                
                                if let driverLocations = objects {
                                    
                                    for driverLocationObject in driverLocations {
                                        if let driverLocation = driverLocationObject["location"] as? PFGeoPoint {
                                            
                                            self.driverOnTheWay = true
                                            
                                            let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            
                                            let riderCLLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                                            
                                            let distance = riderCLLocation.distance(from: driverCLLocation) / 1000
                                            
                                            let roundedDistance = round(distance * 100) / 100
                                            
                                            self.callAnUberButton.setTitle("Your driver is \(roundedDistance) mi away", for: [])
                                            
                                            let latDelta = abs(driverLocation.latitude - self.userLocation.latitude) * 2 + 0.005
                                            
                                            let lonDelta = abs(driverLocation.longitude - self.userLocation.longitude) * 2 + 0.005
                                            
                                            let region = MKCoordinateRegion(center: self.userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
                                            
                                            self.mapView.removeAnnotations(self.mapView.annotations)
                                            
                                            self.mapView.setRegion(region, animated: true)
                                            
                                            let userLocationAnnotation = MKPointAnnotation()
                                            
                                            userLocationAnnotation.coordinate = self.userLocation
                                            
                                            userLocationAnnotation.title = "Your location"
                                            
                                            self.mapView.addAnnotation(userLocationAnnotation)
                                            
                                            let driverLocationAnnotation = MKPointAnnotation()
                                            
                                            driverLocationAnnotation.coordinate = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                            
                                            driverLocationAnnotation.title = driverUsername as? String
                                            
                                            self.mapView.addAnnotation(driverLocationAnnotation)
                                            
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
        
     //   let datePickerView:UIDatePicker = UIDatePicker()
     //   datePickerView.isHidden = true
    }
}
