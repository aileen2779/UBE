//
//  RiderViewController.swift


import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate  {
    
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

        // Textfield
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        fromTextField.delegate = self
        
        tableView.isHidden = true
        
        // Manage tableView visibility via TouchDown in textField
        fromTextField.addTarget(self, action: #selector(textFieldActive), for: UIControlEvents.touchDown)
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
    

    // The sample values
    var fromValues = ["Home Address:\n668 Holland Heights Ave.,\nLas Vegas NV 89123", "Current Location"]
    var toValues = ["668 Holland Heights Ave., Las Vegas NV 89123", "909 Adobe Flat Dr., Henderson NV 89011"]
    let cellReuseIdentifier = "cell"
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    // Using simple subclass to prevent the copy/paste menu
    // This is optional, and a given app may want a standard UITextField
    
    
    //@IBOutlet weak var fromTextField: NoCopyPasteUITextField!
    @IBOutlet weak var fromTextField: CustomTextField!
    @IBOutlet weak var toTextField: CustomTextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func fromTextFieldChanged(_ sender: Any) {
        tableView.isHidden = true    }
    @IBAction func toTextFieldChanged(_ sender: Any) {
        tableView.isHidden = true    }
    
    override func viewDidLayoutSubviews()
    {
        // Assumption is we're supporting a small maximum number of entries
        // so will set height constraint to content size
        // Alternatively can set to another size, such as using row heights and setting frame
        heightConstraint.constant = tableView.contentSize.height
    }
    

    
    // Manage keyboard and tableView visibility
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch:UITouch = touches.first else
        {
            return;
        }
        if touch.view != tableView
        {
            fromTextField.endEditing(true)
            toTextField.endEditing(true)
            tableView.isHidden = true
        }
    }
    
    // Toggle the tableView visibility when click on textField
    func textFieldActive() {
        tableView.isHidden = !tableView.isHidden
    }
    
    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        // TODO: Your app can do something when textField finishes editing
        print("The textField ended editing. Do something based on app requirements.")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        fromTextField.resignFirstResponder()
        toTextField.resignFirstResponder()
        return true
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fromValues.count;
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell!
        // Set text from the data model
        cell.textLabel?.text = fromValues[indexPath.row]
        //cell.textLabel?.font = textField.font
        cell.textLabel?.font =  UIFont(name:"Avenir", size:16)
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.numberOfLines = 3
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Row selected, so set textField to relevant value, hide tableView
        // endEditing can trigger some other action according to requirements
        fromTextField.text = fromValues[indexPath.row]
        toTextField.text = toValues[indexPath.row]
        
        tableView.isHidden = true
        fromTextField.endEditing(true)
        toTextField.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

}
