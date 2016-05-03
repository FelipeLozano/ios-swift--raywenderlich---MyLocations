//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Felipe Lozano on 15/04/16.
//  Copyright © 2016 FelipeCanayo. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import QuartzCore
import AudioToolbox
class CurrentLocationViewController: UIViewController , CLLocationManagerDelegate{
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    
    @IBOutlet weak var containerView: UIView!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    
    var updatingLocation = false
    var lastLocationError: NSError?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    var timer: NSTimer?
    
    var managedObjectContext: NSManagedObjectContext!
    
    var logoVisible = false
    
    lazy var logoButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setBackgroundImage(UIImage(named: "Logo"), forState: .Normal)
        button.sizeToFit()
        button.addTarget(self, action: Selector("getLocation"), forControlEvents: .TouchUpInside)
        button.center.x = CGRectGetMidX(self.view.bounds)
        button.center.y = 220
        return button
    }()
    
    var soundID: SystemSoundID = 0
    
    
    
    @IBAction func getLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        if logoVisible{
            hideLogoView()
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
            
        //startLocationManager()
        updateLabels()
        configureGetButton()
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateLabels()
        configureGetButton()
        loadSoundEffect("Sound.caf")
        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
        
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        // 1
            if newLocation.timestamp.timeIntervalSinceNow < -5 {
                return
            }
        // 2
            if newLocation.horizontalAccuracy < 0 {
                return
            }
        var distance = CLLocationDistance(DBL_MAX)
            if let location = location{
                distance = newLocation.distanceFromLocation(location)
            }
            if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            // 4
            lastLocationError = nil
            location = newLocation
            updateLabels()
            // 5
                if newLocation.horizontalAccuracy <=
                    locationManager.desiredAccuracy {
                    print("*** Foram realizadas !")
                    stopLocationManager()
                    configureGetButton()
                
                    if distance > 0 {
                        performingReverseGeocoding = false
                    }
                }
            
            // The new code begins here:
                if !performingReverseGeocoding {
                    print("*** Indo para geocodificar")
                    performingReverseGeocoding = true
                    geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
                        placemarks, error in
                    print("*** marcadores encontrados: \(placemarks), error: \(error)")
                    
                    self.lastGeocodingError = error
                        if error == nil, let p = placemarks where !p.isEmpty {
                            if self.placemark == nil {
                                print("PRIMEIRO TEMPO!")
                                self.playSoundEffect()
                            }
                            
                            self.placemark = p.last!
                        } else {
                            self.placemark = nil
                        }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                    })
                }
            // End of the new code
        }else if distance < 1.0 {
                let timeInterval = newLocation.timestamp.timeIntervalSinceDate(
                    location!.timestamp)
                    if timeInterval > 10 {
                        print("*** Force done!")
                        stopLocationManager()
                        updateLabels()
                        configureGetButton()
                    }
                }
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Localização serviços para deficientes motores",
                                      message: "Ative os serviços de localização para este app em Configurações.",
                                      preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default,
                                     handler: nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateLabels() {
        if let location = location {
            latitudeLabel.text =
                String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text =
                String(format: "%.8f", location.coordinate.longitude)
            tagButton.hidden = false
            messageLabel.text = ""
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
            
            latitudeTextLabel.hidden = false
            longitudeTextLabel.hidden = false
            
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.hidden = true
            //messageLabel.text = "Toque em 'Get My Location' para Iniciar"
            // The new code starts here:
            let statusMessage: String
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain &&
                    error.code == CLError.Denied.rawValue {
                    statusMessage = "Localização de Serviço desabilitado"
                } else {
                    statusMessage = "Error Obter Localização"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Localização de Serviço desabilitado "
            } else if updatingLocation {
                statusMessage = "Procurando..."
            } else {
               // statusMessage = "Toque em 'Get My Location' para Iniciar"
                statusMessage = ""
                showLogoView()
            }
            messageLabel.text = statusMessage
            
            latitudeTextLabel.hidden = false
            longitudeTextLabel.hidden = false
        
        }
    }
    
    
    func stopLocationManager() {
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy =
            kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            //time
            timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self,
                                                           selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
        }
    }

    func configureGetButton() {
        let spinnerTag = 1000
        if updatingLocation {
            getButton.setTitle("Stop", forState: .Normal)
            if view.viewWithTag(spinnerTag) == nil {
                let spinner = UIActivityIndicatorView(
                    activityIndicatorStyle: .White)
                spinner.center = messageLabel.center
                spinner.center.y += spinner.bounds.size.height/2 + 15
                spinner.startAnimating()
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        } else {
            getButton.setTitle("Get My Location", forState: .Normal)
            if let spinner = view.viewWithTag(spinnerTag) {
                spinner.removeFromSuperview()
            }
        }
    }
    
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var line1 = ""
       // line1.addText(placemark.subThoroughfare, withSeparator: "")
        line1.addText(placemark.subThoroughfare)
        line1.addText(placemark.thoroughfare, withSeparator: " ")
        var line2 = ""
        // line2.addText(placemark.locality, withSeparator: "")
        line2.addText(placemark.locality)
        line2.addText(placemark.administrativeArea, withSeparator: " ")
        line2.addText(placemark.postalCode, withSeparator: " ")
        line1.addText(line2, withSeparator: "\n")
        return line1
    }
    //Cancelar interroper a procura
    
    func didTimeOut() {
        print("*** Time out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain",
                                        code: 1, userInfo: nil)
            updateLabels()
            configureGetButton()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    func showLogoView() {
        if !logoVisible {
            logoVisible = true
            containerView.hidden = true
            view.addSubview(logoButton)
        }
    }
    func hideLogoView() {
        if !logoVisible { return }
        
        logoVisible = false
        containerView.hidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        let centerX = CGRectGetMidX(view.bounds)
        
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.removedOnCompletion = false
        panelMover.fillMode = kCAFillModeForwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(CGPoint: containerView.center)
        panelMover.toValue = NSValue(CGPoint: CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        panelMover.delegate = self
        containerView.layer.addAnimation(panelMover, forKey: "panelMover")
        
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.removedOnCompletion = false
        logoMover.fillMode = kCAFillModeForwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(CGPoint: logoButton.center)
        logoMover.toValue = NSValue(CGPoint:CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoMover, forKey: "logoMover")
        
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.removedOnCompletion = false
        logoRotator.fillMode = kCAFillModeForwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * M_PI
        logoRotator.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoRotator, forKey: "logoRotator")
    }
    override func animationDidStop(anim: CAAnimation,
                                   finished flag: Bool) {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }
    
    // MARK: - Sound Effect
    func loadSoundEffect(name: String) {
        if let path = NSBundle.mainBundle().pathForResource(name,
                                                            ofType: nil) {
            let fileURL = NSURL.fileURLWithPath(path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL, &soundID)
            if error != kAudioServicesNoError {
                print("Error code \(error) loading sound at path: \(path)")
            }
        }
    }
    func unloadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }
    func playSoundEffect() {
        AudioServicesPlaySystemSound(soundID)
    }
    
    


}

