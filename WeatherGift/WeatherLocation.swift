//
//  WeatherLocation.swift
//  WeatherGift
//
//  Created by Christopher Rea on 10/7/21.
//

import Foundation

class WeatherLocation: Codable {
    var name: String
    var latitude: Double
    var longitude: Double
    
    init(name: String, latitude: Double, longitude: Double){
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    func getData() {
        let urlString = "https://api.openweathermap.org/data/2.5/onecall?lat=\(latitude)&lon=\(longitude)&exclude=minutely&units=imperial&appid=\(APIkeys.openWeatherKey)"
        
        print("We are accesing URL")
        
        guard let url = URL(string: urlString) else {
            print("Sould not create url from \(urlString)")
            return
        }
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error")
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                print(" \(json)")
            } catch {
                print(" Json error: \(error.localizedDescription)")
            }
      }
        task.resume()
    }
}





















