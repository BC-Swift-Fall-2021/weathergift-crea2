//
//  LocationDetailViewController.swift
//  WeatherGift
//
//  Created by Christopher Rea on 10/11/21.
//

import UIKit
import CoreLocation

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE, MMM d"
    return dateFormatter
}()

class LocationDetailViewController: UIViewController {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var weatherDetail: WeatherDetail!
    var locationIndex = 0
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        clearUserInterface()
        
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.dataSource = self
        
        if locationIndex == 0 {
            getLocation()
        }
        
        updaterUserInterface()
    }
    
    
    func clearUserInterface() {
        dateLabel.text = ""
        placeLabel.text = ""
        temperatureLabel.text = ""
        summaryLabel.text = ""
        imageView.image = UIImage()
        
    }
    
    func updaterUserInterface() {
        let pageViewController = UIApplication.shared.windows.first!.rootViewController as! PageViewController
        let weatherLocation = pageViewController.weatherLocations[locationIndex]
        weatherDetail = WeatherDetail(name: weatherLocation.name, latitude: weatherLocation.latitude, longitude: weatherLocation.longitude)
                                      
        
        
        pageControl.numberOfPages = pageViewController.weatherLocations.count
        pageControl.currentPage = locationIndex
        
        weatherDetail.getData {
            DispatchQueue.main.async {
                dateFormatter.timeZone = TimeZone(identifier: self.weatherDetail.timeZone)
                let usableDate = Date(timeIntervalSince1970: self.weatherDetail.currentTime)
                self.dateLabel.text = dateFormatter.string(from: usableDate)
                //timezone?
                self.placeLabel.text = self.weatherDetail.name
                self.temperatureLabel.text = "\(self.weatherDetail.temperature)°"
                self.summaryLabel.text = self.weatherDetail.summary
                self.imageView.image = UIImage(named: self.weatherDetail.dayIcon)
                self.tableView.reloadData()
                self.collectionView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            let destination = segue.destination as! LocationListViewController
            let pageViewController = UIApplication.shared.windows.first!.rootViewController as! PageViewController
            destination.weatherLocations = pageViewController.weatherLocations
    }
    // need to fix, probably 6.7
       @IBAction func unwindFromLocationListViewController(segue: UIStoryboardSegue) {
        let source = segue.source as! LocationListViewController
        locationIndex = source.selectedLocationIndex
        
        let pageViewController = UIApplication.shared.windows.first!.rootViewController as!
            PageViewController
        pageViewController.weatherLocations = source.weatherLocations
        
        pageViewController.setViewControllers([pageViewController.createLocationDetailViewController(forPage: locationIndex)], direction: .forward, animated: false, completion: nil)
       }
    
    @IBAction func pageControlTapped(_ sender: UIPageControl) {
        let pageViewController = UIApplication.shared.windows.first!.rootViewController as!
            PageViewController
        
        var direction: UIPageViewController.NavigationDirection = .forward
        if sender.currentPage < locationIndex {
            direction = .reverse
        }
        
        pageViewController.setViewControllers([pageViewController.createLocationDetailViewController(forPage: sender.currentPage)], direction: direction, animated: true, completion: nil)
    }
}

extension LocationDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weatherDetail.dailyWeatherData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as!
            DailyTableViewCell
        cell.dailyWeather = weatherDetail.dailyWeatherData[indexPath.row]
        return cell
   }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension LocationDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weatherDetail.hourlyWeatherData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let hourlyCell = collectionView.dequeueReusableCell(withReuseIdentifier: "HourlyCell", for: indexPath) as! HourlyCollectionViewCell
        hourlyCell.hourlyWeather = weatherDetail.hourlyWeatherData[indexPath.row]
        return hourlyCell
    }
}

extension LocationDetailViewController: CLLocationManagerDelegate {
    
    func getLocation() {
        // creating CLLocationManager will auto check authorization
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Checking authentication status.")
        handleAuthenticationStatus(status: status)
    }
    
    func handleAuthenticationStatus(status: CLAuthorizationStatus) {
        
        switch status {
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            self.oneButtonAlert(title: "Location services denied", message: "It maybe that parental controls are restricting location use in this app.")
        case .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            print("Unkown case of status \(status)")
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didupdateLocations locations: [CLLocation]) {
        print("updating location")
        let currentLocation = locations.last ?? CLLocation()
        print("current location is \(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)")
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            var locationName = ""
            if placemarks != nil {
                let placemark = placemarks?.last
                locationName = placemark?.name ?? "Parts Unknown"
            } else {
                print("error: retrieving place.")
                locationName = "Could not find Location"
            }
            
            // update weatherlocation[0]
            
            let pageViewController = UIApplication.shared.windows.first!.rootViewController as! PageViewController
            pageViewController.weatherLocations[self.locationIndex].latitude = currentLocation.coordinate.latitude
            pageViewController.weatherLocations[self.locationIndex].longitude = currentLocation.coordinate.longitude
            pageViewController.weatherLocations[self.locationIndex].name = locationName
            
            self.updaterUserInterface()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription). Failed to get device location.")
    }
}














