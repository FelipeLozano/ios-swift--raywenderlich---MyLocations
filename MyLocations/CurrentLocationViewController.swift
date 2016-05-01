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

class CurrentLocationViewController: UIViewController , CLLocationManagerDelegate{
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
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
                statusMessage = "Toque em 'Get My Location' para Iniciar"
            }
            messageLabel.text = statusMessage
        
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
        if updatingLocation {
            getButton.setTitle("Stop", forState: .Normal)
        } else {
            getButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var line1 = ""
        
        if let s = placemark.subThoroughfare {
            line1 += s + " "
        }
        if let s = placemark.thoroughfare {
            line1 += s
        }
        
        var line2 = ""
        
        if let s = placemark.locality {
            line2 += s + " "
        }
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        if let s = placemark.postalCode {
            line2 += s
        }
        
        return line1 + "\n" + line2
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
    
  
    


}

