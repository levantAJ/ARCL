//
//  ViewController.swift
//  ARCL
//
//  Created by levantAJ on 8/13/17.
//  Copyright © 2017 levantAJ. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MapKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var searchWrapperView: UIVisualEffectView!
    @IBOutlet weak var wrapperViewTopContraint: NSLayoutConstraint!
    @IBOutlet weak var searchResultsWrapperView: UIVisualEffectView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var routeDetailWrapperView: UIVisualEffectView!
    @IBOutlet weak var routeDetailWrapperViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var routeDetailLabel: UILabel!
    
    fileprivate lazy var locationManager: CLLocationManager = CLLocationManager()
    fileprivate lazy var localSearchCompleter: MKLocalSearchCompleter = MKLocalSearchCompleter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.showsTraffic = true
        mapView.showsBuildings = true
        mapView.showsScale = true
        mapView.userTrackingMode = .follow
        mapView.showsUserLocation = true
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Constant.ViewController.AnnotationViewIdentifier)
        
        wrapperViewTopContraint.constant = searchWrapperViewDefaultTopConstant
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        searchBar.delegate = self
        
        localSearchCompleter.delegate = self
        localSearchCompleter.region = mapView.region
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingSessionConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
}

// MARK: - Users Interactions

extension ViewController {
    @IBAction func searchWrapperViewDragged(sender: Any?) {
        searchBar.resignFirstResponder()
        let recognizer = sender as! UIPanGestureRecognizer
        let point = recognizer.location(in: view)
        if recognizer.state == .ended {
            let top = point.y > UIScreen.main.bounds.height/2 ? searchWrapperViewDefaultTopConstant : Constant.ViewController.TopPadding
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.wrapperViewTopContraint.constant = top
                self?.view.layoutIfNeeded()
            }
        } else {
            wrapperViewTopContraint.constant = min(max(point.y, Constant.ViewController.TopPadding), searchWrapperViewDefaultTopConstant)
        }
    }
    
    @objc func directionButtonTapped(_ button: UIButton) {
        let annotation = button.layer.value(forKey: Constant.ViewController.AnnotationKeyPath) as! MKAnnotation
        let request = MKDirectionsRequest()
        request.source = mapView.userLocation.mapItem
        request.destination = annotation.mapItem
        request.transportType = .any
        request.requestsAlternateRoutes = true
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] (response, error) in
            guard let strongSelf = self else { return }
            if let response = response,
                let route = response.routes.first {
                strongSelf.mapView.add(route.polyline, level: .aboveRoads)
                strongSelf.routeDetailLabel.text = "\(route.distance)m : \(route.expectedTravelTime/1000)minute"
                strongSelf.routeDetailWrapperViewBottomConstraint.constant = -strongSelf.routeDetailWrapperView.bounds.height
                strongSelf.routeDetailWrapperView.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    strongSelf.routeDetailWrapperViewBottomConstraint.constant = 70.0
                    strongSelf.wrapperView.layoutIfNeeded()
                }
                //TODO: Go to AR mode
            } else {
                let alert = UIAlertController(title: "Cannot find directions!", message: "Please try with another destination, thanks", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                strongSelf.present(alert, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController {
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

// MARK: - MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        localSearchCompleter.region = mapView.region
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Constant.ViewController.AnnotationViewIdentifier) as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: Constant.ViewController.AnnotationViewIdentifier)
            let button = UIButton(type: .custom)
            button.frame = CGRect(origin: .zero, size: CGSize(width: 22, height: 22))
            button.setImage(UIImage(named: "direction"), for: .normal)
            button.layer.setValue(annotation, forKey: Constant.ViewController.AnnotationKeyPath)
            button.addTarget(self, action: #selector(directionButtonTapped(_:)), for: .touchUpInside)
            annotationView?.rightCalloutAccessoryView = button
            annotationView?.canShowCallout = true
            annotationView?.animatesWhenAdded = true
        }
        annotationView?.annotation = annotation
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .green
        renderer.lineWidth = 8.0
        return renderer
    }
}

// MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    
}

// MARK: - UISearchBarDelegate

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResultsWrapperView.isHidden = searchText.isEmpty
        localSearchCompleter.queryFragment = searchText
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension ViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localSearchCompleter.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.ViewController.TableViewCellIdentifier, for: indexPath)
        cell.textLabel?.text = localSearchCompleter.results[indexPath.row].title
        cell.detailTextLabel?.text = localSearchCompleter.results[indexPath.row].subtitle
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let completion = localSearchCompleter.results[indexPath.row]
        let request = MKLocalSearchRequest(completion: completion)
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { [weak self] (response, error) in
            guard let response = response else { return }
            for (index, mapItem) in response.mapItems.enumerated() {
                let annotation = MKPointAnnotation()
                annotation.title = mapItem.placemark.title
                annotation.coordinate = mapItem.placemark.coordinate
                self?.mapView.addAnnotation(annotation)
                if index == 0 {
                    self?.mapView.setCenter(annotation.coordinate, animated: true)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
        searchResultsWrapperView.isHidden = true
        searchBar.resignFirstResponder()
    }
}

// MARK: - Privates

extension ViewController {
    var searchWrapperViewDefaultTopConstant: CGFloat {
        return UIScreen.main.bounds.height - searchWrapperView.bounds.height - Constant.ViewController.BottomPadding
    }
    
    @objc func keyboardWillShow() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.wrapperViewTopContraint.constant = Constant.ViewController.TopPadding
            self?.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide() {
        
    }
}

struct Constant {}

extension Constant {
    struct ViewController {
        static let TopPadding = CGFloat(20)
        static let BottomPadding = CGFloat(100)
        static let AnnotationViewIdentifier = "AnnotationView"
        static let TableViewCellIdentifier = "TableViewCell"
        static let AnnotationKeyPath = "AnnotationKeyPath"
    }
}
