import UIKit
import Parse

class ViewController: UIViewController {
    
    @IBOutlet var userSignupSwitch: UISwitch!
    
    var signUpMode = true
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    @IBOutlet var signupOrLoginButton: UIButton!
    
    @IBAction func signupOrLogin(_ sender: AnyObject) {
        
        if usernameTextField.text == ""{
            animateMe(textField: self.usernameTextField)
            return
        }

        if passwordTextField.text == "" {
            animateMe(textField: self.passwordTextField)
            return
        }

        if signUpMode {
                
            let user = PFUser()
                
            user.username = usernameTextField.text
            user.password = passwordTextField.text
                
            user["isDriver"] = userSignupSwitch.isOn
            user.signUpInBackground(block: { (success, error) in
                    if let error = error {
                        var displayedErrorMessage = "Please try again later"
                        let error = error as NSError
                        if let parseError = error.userInfo["error"] as? String {
                            displayedErrorMessage = parseError
                        }
                        self.displayAlert(title: "Sign Up Failed", message: displayedErrorMessage)
                        print("Sign Up Failed")
                        
                    } else {
                        
                        print("Sign Up Successful")
                       
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
                        self.displayAlert(title: "Sign Up Failed", message: displayedErrorMessage)
                    } else {
                        
                        print("Log In Successful")
                        if let isDriver = PFUser.current()?["isDriver"] as? Bool {
                            if isDriver {
                                self.performSegue(withIdentifier: "showDriverViewController", sender: self)
                            } else {
                                self.performSegue(withIdentifier: "showRiderViewController", sender: self)
                            }
                        }
                    }
                })
        }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func displayAlert(title: String, message: String) {
        
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

}
