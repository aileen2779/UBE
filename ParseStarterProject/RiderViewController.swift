//
//  RiderViewController.swift


import UIKit
import Parse
import MapKit

class RiderViewController: UIViewController,
                        MKMapViewDelegate,
                        CLLocationManagerDelegate,
                        UITableViewDataSource,
                        UITableViewDelegate,
                        UITextFieldDelegate  {
    
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
        
            // Check for empty fields
            if (fromTextField.text!.isEmpty) {
                animateMe(textField: fromTextField)
                return
            } else if (toTextField.text!.isEmpty){
                animateMe(textField: toTextField)
                return
            } else if (whenTextField.text!.isEmpty){
                animateMe(textField: whenTextField)
                return
            } else {
                //
            }
        
            /*
            callAnUberButton.setTitle("Go ahead and schedule this ride", for: [])
            riderRequestActive = false
            let query = PFQuery(className: "RiderRequest")
            
            query.whereKey("username", equalTo: (PFUser.current()?.username)!)
            query.findObjectsInBackground(block: {
                    (objects, error) in
                    if let riderRequests = objects {
                        for riderRequest in riderRequests {
                            riderRequest.deleteInBackground()
                        }
                    }
                }
            )
            */
        
        let optionMenu = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: .actionSheet)
        let scheduleAction = UIAlertAction(title: "Schedule this ride", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            
            //Insert into AWS
            if self.userLocation.latitude != 0 && self.userLocation.longitude != 0 {
                self.riderRequestActive = true
                //self.callAnUberButton.setTitle("Cancel this ride", for: [])
                let riderRequest = PFObject(className: "RiderRequest")
                riderRequest["username"] = PFUser.current()?.username
                riderRequest["location"] = PFGeoPoint(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
                riderRequest.saveInBackground(
                    block: {
                        (success, error) in
                        if success {
                            print("Called an uber")
                        } else {
                            self.callAnUberButton.setTitle("Call An Uber", for: [])
                            self.riderRequestActive = false
                            self.displayAlert(title: "Could not call Uber", message: "Please try again!")
                        }
                }
                )
            } else {
                
                self.displayAlert(title: "Could not schedule a ride", message: "Cannot detect your location.")
                
            }
            //End insert
            
            
            
        })
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        
        optionMenu.addAction(scheduleAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
        
        

    }
    

    
    @IBOutlet var callAnUberButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        addShadow(textField: fromTextField)
        addShadow(textField: toTextField)
        addShadow(textField: whenTextField)

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        callAnUberButton.isHidden = true

        /*
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
 */
        self.callAnUberButton.isHidden = false
        
        // Textfield
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        fromTextField.delegate = self
        toTextField.delegate = self
        whenTextField.delegate = self

        tableView.isHidden = true
        
        // Manage tableView visibility via TouchDown in textField
        fromTextField.addTarget(self, action: #selector(fromTextFieldActive), for: UIControlEvents.touchDown)
        toTextField.addTarget(self, action: #selector(toTextFieldActive), for: UIControlEvents.touchDown)
        whenTextField.addTarget(self, action: #selector(whenTextFieldActive), for: UIControlEvents.touchDown)
        
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
    var values = [""]

    let cellReuseIdentifier = "cell"
    var editField = ""
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    // Using simple subclass to prevent the copy/paste menu
    // This is optional, and a given app may want a standard UITextField
    
    
    //@IBOutlet weak var fromTextField: NoCopyPasteUITextField!
    @IBOutlet weak var fromTextField: CustomTextField!
    @IBOutlet weak var toTextField: CustomTextField!
    @IBOutlet weak var whenTextField: CustomTextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func fromTextFieldChanged(_ sender: Any) {
        tableView.isHidden = true

    }
    @IBAction func toTextFieldChanged(_ sender: Any) {
        tableView.isHidden = true

    }
    
    @IBAction func whenTextFieldChanged(_ sender: Any) {
        tableView.isHidden = true
    }
    
    
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
            whenTextField.endEditing(true)
            tableView.isHidden = true
        }

        whenTextField.isEnabled = true

    }
    
    // Toggle the tableView visibility when click on textField
    func fromTextFieldActive() {
        values = ["Home:\n668 Holland Heights Ave.,\nLas Vegas NV 89123",
                  "Current Location"]
        tableView.reloadData()
        tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.size.width, height: tableView.contentSize.height + 100)
        tableView.isHidden = !tableView.isHidden
        editField = "fromTextField"
}

    func toTextFieldActive() {
 
        values = ["546 Martin Luther King Blvd.,\nLas Vegas NV 89000",
                  "909 Adobe Flat Dr.,\nHenderson NV 89011",
                "238 Highgate St.\nHenderson, NV 89012"]
        tableView.reloadData()
        tableView.frame = CGRect(x: tableView.frame.origin.x, y: 200, width: tableView.frame.size.width, height: tableView.contentSize.height + 100)
        tableView.isHidden = !tableView.isHidden
        editField = "toTextField"

    }

    func whenTextFieldActive() {
        showDatePicker()
        whenTextField.isEnabled = false

    }

    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        // TODO: Your app can do something when textField finishes editing
        print("The textField ended editing. Do something based on app requirements.")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        fromTextField.resignFirstResponder()
        toTextField.resignFirstResponder()
        whenTextField.resignFirstResponder()
        return true
    }

    func showDatePicker() {
        let min = Date()
        let max = Date().addingTimeInterval(60 * 60 * 24 * 30)
        let picker = DateTimePicker.show(minimumDate: min, maximumDate: max)
        picker.highlightColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 138.0/255.0, alpha: 1)
        picker.darkColor = UIColor.darkGray
        picker.doneButtonTitle = " Pick This date"
        picker.todayButtonTitle = "Today"
        picker.is12HourFormat = true
        picker.dateFormat = "MM/dd/YYYY hh:mm aa"
        //        picker.isDatePickerOnly = true
        picker.completionHandler = { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/YYYY hh:mm aa"
            
            self.whenTextField.text = formatter.string(from: date)
            self.whenTextField.isEnabled = true
            return
        }
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count;
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell!
        // Set text from the data model
        cell.textLabel?.text = values[indexPath.row]
        //cell.textLabel?.font = textField.font
        cell.textLabel?.font =  UIFont(name:"Avenir", size:16)
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.numberOfLines = 3
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Row selected, so set textField to relevant value, hide tableView
        // endEditing can trigger some other action according to requirements
        
        if (editField == "fromTextField") {
            fromTextField.text = values[indexPath.row].replacingOccurrences(of: "Home:", with: "")
        } else if (editField == "toTextField") {
            toTextField.text = values[indexPath.row]
        } else {
            print(editField)
        }
        
        tableView.isHidden = true
        fromTextField.endEditing(true)
        toTextField.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

    
    func animateMe(textField: UITextField) {
        
        let _thisTextField = textField
        
        UIView.animate(withDuration: 0.1, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {_thisTextField.center.x += 10 }, completion: nil)
        UIView.animate(withDuration: 0.1, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {_thisTextField.center.x -= 20 }, completion: nil)
        UIView.animate(withDuration: 0.1, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {_thisTextField.center.x += 10 }, completion: nil)
    }
    
    func addShadow(textField: UITextField) {
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.layer.masksToBounds = false
        textField.layer.shadowColor = UIColor.black.cgColor
        textField.layer.shadowOffset = CGSize.zero
        textField.layer.shadowOpacity = 0.5
        textField.layer.shadowRadius = 5.0
    }
    
}
