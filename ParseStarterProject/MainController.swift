import UIKit
import Parse
import LocalAuthentication
import AudioToolbox


class MainController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var userSignupSwitch: UISwitch!
    
    var signUpMode = false
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    @IBOutlet var signupOrLoginButton: UIButton!
    
    @IBAction func signupOrLogin(_ sender: AnyObject) {
        
    }

    
    @IBOutlet var signupSwitchButton: UIButton!
    
    @IBOutlet var driverLabel: UILabel!
    @IBOutlet var riderLabel: UILabel!
    @IBAction func switchSignupMode(_ sender: AnyObject) {
        
        if signUpMode {
            signupOrLoginButton.setTitle("Log In", for: [])
            signupSwitchButton.setTitle("Switch To Sign Up", for: [])
            signUpMode = false
            userSignupSwitch.isHidden = true
            riderLabel.isHidden = true
            driverLabel.isHidden = true
        } else {
            signupOrLoginButton.setTitle("Sign Up", for: [])
            signupSwitchButton.setTitle("Switch To Log In", for: [])
            signUpMode = true
            userSignupSwitch.isHidden = false
            riderLabel.isHidden = false
            driverLabel.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let isDriver = PFUser.current()?["isDriver"] as? Bool {
            if isDriver {
                self.performSegue(withIdentifier: "showDriverViewController", sender: self)
            } else {
                self.performSegue(withIdentifier: "showRiderViewController", sender: self)
            }
        }
    }
    
    
    @IBOutlet weak var loginStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        showSegmentedControl()
        loginToDo()
    }
    @IBOutlet weak var loginButton: UIButton!
    
    func loginToDo() {
        loginStackView.isHidden = false
        loginButton.setTitle("Log In", for: .normal)
        loginButton.isEnabled = true
        touchIDIcon.isHidden = false
        
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "username") != nil {
            usernameTextField.text = preferences.object(forKey: "username") as? String
            passwordTextField.text = preferences.object(forKey: "password") as? String
        }
        
        if preferences.object(forKey: "isTouchIDEnrolled") != nil {
            touchIDButton.isHidden = false
        }
    }

    func registerToDo() {
        loginStackView.isHidden = false
        loginButton.setTitle("Register", for: .normal)
        touchIDIcon.isHidden = true
        touchIDButton.isHidden = true
    }
    

    @IBAction func loginButtonTapped(_ sender: Any) {
        print(selector.selectedIndex)
        if usernameTextField.text == ""{
            animateMe(textField: self.usernameTextField)
            return
        }
        
        if passwordTextField.text == "" {
            animateMe(textField: self.passwordTextField)
            return
        }
        
        
        // disable login button to prevent logging in twice
        loginButton.isEnabled = false
        
        if signUpMode {
            
            let user = PFUser()
            
            user.username = usernameTextField.text
            user.password = passwordTextField.text
            
            user["isDriver"] = (selector.selectedIndex == 0 ? true : false)
            user.signUpInBackground(block: { (success, error) in
                if let error = error {
                    var displayedErrorMessage = "Please try again later"
                    let error = error as NSError
                    if let parseError = error.userInfo["error"] as? String {
                        displayedErrorMessage = parseError
                    }
                    self.displayAlert(title: "Registration Failed", message: displayedErrorMessage)
                    
                    print("Registration Failed")
                    self.loginButton.isEnabled = true
                } else {
                    
                    print("Registration Successful")
                    
                    if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                        if isDriver {
                            self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                        } else {
                            self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                        }
                    }
                }
            }
            )
            
        } else {

            
            PFUser.logInWithUsername(inBackground: usernameTextField.text!, password: passwordTextField.text!, block: { (user, error) in
                if let error = error {
                    var displayedErrorMessage = "Please try again later"
                    let error = error as NSError
                    if let parseError = error.userInfo["error"] as? String {
                        displayedErrorMessage = parseError
                    }
                    self.displayAlert(title: "Log In Failed", message: displayedErrorMessage)
                    
                    print("Log In Failed")
                    self.loginButton.isEnabled = true
                } else {
                    
                    print("Log In Successful")
                    if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                        if isDriver {
                            self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                        } else {
                            self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                        }
                    }
                    
                    let preferences = UserDefaults.standard
                    preferences.setValue(self.usernameTextField.text!, forKey: "username")
                    preferences.setValue(self.passwordTextField.text!, forKey: "password")
                    preferences.setValue(self.selector.selectedIndex, forKey: "isDriverSelector")
                    preferences.setValue(true, forKey: "isTouchIdEnrolled")

                }
            })
        }

    }
    
    @IBAction func selectorDidChange(_ sender: Any) {
//        print(selector.selectedIndex)
        usernameTextField.placeholder = (selector.selectedIndex == 0) ? "Passenger ID" : "Driver ID"
        
    }
    

    @IBOutlet weak var selector: NPSegmentedControl!
    
    func showSegmentedControl() {
        
        // find out if previously logged in
        let preferences = UserDefaults.standard

        var isDriver = 0
        if preferences.object(forKey: "isDriverSelector") != nil {
            //assign preferences to selector
            isDriver = (preferences.object(forKey: "isDriverSelector") as! Int)
        }
        
        let myElements = ["Passenger", "Driver"]
        selector.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
        selector.cursor = UIImageView(image: UIImage(named: "tabindicator"))
        
        selector.unselectedFont = UIFont(name: "HelveticaNeue-Light", size: 20)
        selector.selectedFont = UIFont(name: "HelveticaNeue-Bold", size: 20)
        selector.unselectedTextColor = UIColor(white: 1, alpha: 0.8)
        selector.unselectedColor = UIColor(red: 10/255, green: 137/255, blue: 169/255, alpha: 0.5)
        selector.selectedTextColor = UIColor(white: 1, alpha: 1)
        selector.selectedColor = UIColor(red: 10/255, green: 137/255, blue: 169/255, alpha: 1)
        selector.cursorPosition = CursorPosition.Bottom
        
        selector.setItems(items: myElements)
//        labelIndex.text = "Index : \(selector.selectedIndex)"
        print(isDriver)
        selector.selectCell(index: isDriver, animate: true)


    }
    
    // Touch ID objects
    @IBOutlet weak var touchIDButton: UIButton!
    @IBOutlet weak var touchIDIcon: UIImageView!
    
    @IBAction func touchIDButtonTapped(_ sender: Any) {
        touchAuthenticateUser()
    }
    
    func touchAuthenticateUser() {
        
        // Hide the keyboard
        view.endEditing(true)
        
        let touchIDManager = TouchIDManager()
        
        touchIDManager.authenticateUser(success: { () -> () in
            OperationQueue.main.addOperation({ () -> Void in
//                self.loginDone()
            })
        }, failure: { (evaluationError: NSError) -> () in
            switch evaluationError.code {
            case LAError.Code.systemCancel.rawValue:
                print("Authentication cancelled by the system")
            case LAError.Code.userCancel.rawValue:
                print("Authentication cancelled by the user")
            case LAError.Code.userFallback.rawValue:
                print("User wants to use a password")
            case LAError.Code.touchIDNotEnrolled.rawValue:
                print("TouchID not enrolled")
            case LAError.Code.passcodeNotSet.rawValue:
                print("Passcode not set")
            default:
                print("Authentication failed")
                //self.loginToDo()
            }
            self.loginToDo()
        })
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func displayAlert(title: String, message: String) {
        vibrate(howMany: 1)
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertcontroller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertcontroller, animated: true, completion: nil)
    }

    func animateMe(textField: UITextField) {
        
        let _thisTextField = textField
        
        UIView.animate(withDuration: 0.1, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {_thisTextField.center.x += 10 }, completion: nil)
        UIView.animate(withDuration: 0.1, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {_thisTextField.center.x -= 20 }, completion: nil)
        UIView.animate(withDuration: 0.1, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: {_thisTextField.center.x += 10 }, completion: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    func vibrate(howMany: Int) {
        let x = Int(howMany)
        for _ in 1...x {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            //sleep(1)
        }
    }
}
