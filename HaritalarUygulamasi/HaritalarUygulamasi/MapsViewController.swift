//
//  ViewController.swift
//  HaritalarUygulamasi
//
//  Created by Vural ÇETİN on 13.07.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController , MKMapViewDelegate ,CLLocationManagerDelegate {
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var notTextField: UITextField!
    
    
    
    var locationManager = CLLocationManager()
    var secilenLatiutude = Double()
    var secilenLongitude = Double()
    
    var secilenIsım = ""
    var secilenID : UUID?
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumsec(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsım != "" {
            //Core Datadan verileri çek
            if let uuidString = secilenID?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@",uuidString )
                fetchRequest.returnsObjectsAsFaults = false
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                                if let not = sonuc.value(forKey: "not") as? String {
                                    annotationSubTitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double{
                                        annotationLatitude = latitude
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubTitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            isimTextField.text = annotationTitle
                                            notTextField.text = annotationSubTitle
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                            
                                            
                                            
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                           
                            
                            
                            
                            
                        }
                    }
                    
                    
                
                }catch {
                    print("hata")
                    
                    
                }
                
                
                
                
            }
        }else {
            
            //yeni veri ekleme.
        }
        
        
        
        // Do any additional setup after loading the view.
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseid = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseid)
        
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseid)
            pinView?.canShowCallout = true
            pinView?.tintColor = .green
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else {
            pinView?.annotation = annotation
            
    }
        return pinView
        
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsım != "" {
                var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
                if let placemarks = placemarkDizisi {
                    if placemarks.count > 0 {
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                    }
                }
               
            
        }
    }
    
    
    
    
    
    @objc func konumsec(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom : mapView)
            secilenLatiutude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if secilenIsım == "" {
//       // print(locations[0].coordinate.latitude)
        //print(locations[0].coordinate.longitude)
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
        }
    }
    
    
    @IBAction func kaydetButtonTiklandi(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(isimTextField.text, forKey: "isim")
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(secilenLatiutude, forKey: "latitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("kayıt edildi")
        }catch  {
            print("hata")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
        
        
        
        
        
        
        
        
    }
    

}

