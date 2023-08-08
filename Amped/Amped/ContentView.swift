//
//  ContentView.swift
//  Amped
//
//  Created by 0x7B5 on 8/8/23.
//

import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

struct ContentView: View {
    @State private var initialRegionSet = false
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var annotations: [StationAnnotation] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: annotations) { stationAnnotation -> MapPin in
                switch stationAnnotation.type {
                case .empty:
                    return MapPin(coordinate: stationAnnotation.coordinate, tint: .red)
                case .ebikeOnly:
                    return MapPin(coordinate: stationAnnotation.coordinate, tint: .blue)
                }
            }
            .onAppear(perform: loadData)
            .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(true)

                VStack {
                    ProgressView()
                    Text("Loading...")
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
            }
            
            VStack {
                HStack {
                    // Refresh Button
                    Button(action: {
                        loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                    )
                    .padding(.leading, 16)
//                    .padding(.top, 16)
                    
                    Spacer() // This pushes the logo to the center

//                    // Amped Logo
//                    HStack(spacing: 8) {
//                        Text("Amped")
//                            .font(.largeTitle)
//                            .bold()
//                            .foregroundColor(Color(red: 38/255, green: 52/255, blue: 113/255))
//
//                        Image(systemName: "bolt.fill")
//                            .font(.system(size: 30))
//                            .foregroundColor(Color(red: 235/255, green: 31/255, blue: 42/255))
//                    }
//                    .padding(.vertical, 4)
//                    .padding(.horizontal, 30)
//                    .background(
//                        RoundedRectangle(cornerRadius: 10)
//                            .fill(Color.white.opacity(0.8))
//                    )
                    
//                    Spacer() // Keeps empty space after the logo
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(red: 235/255, green: 31/255, blue: 42/255))
                        .padding(.trailing, 16)
                    
                }
                .padding(.top, 16)
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: 20)
                                Text("E-bikes Only")
                                    .font(.footnote)
                                    .foregroundColor(Color.black)
                            }
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 20, height: 20)
                                Text("Empty Only")
                                    .font(.footnote)
                                    .foregroundColor(Color.black)
                            }
                        }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 5)
                    .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white.opacity(0.8))
                                        )
                        .padding(.leading, 16)
                    
                    Spacer()
                    VStack(spacing: 16) {
                        Button(action: {
                            if let userLocation = locationManager.location {
                                updateRegion(to: userLocation.coordinate)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50) // Square frame
                                
                                Image(systemName: "location")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(Color.black)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: {
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .frame(width: 50, height: 50) // Square frame
                                
                                Image(systemName: "slider.horizontal.3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(Color.black)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 30)
            }
        }
        .onReceive(locationManager.$location) { location in
            if !initialRegionSet, let location = location {
                updateRegion(to: location.coordinate)
                initialRegionSet = true
            }
        }
    }
    
    func loadData() {
        isLoading = true
        let api = CitibikeAPI()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            isLoading = false
        }
        
        api.fetchStations { stations in
            isLoading = false
            let categories = api.categorizeStations(stations: stations)
            
            annotations = categories.emptyStations.map { StationAnnotation(coordinate: $0.location.toCLLocationCoordinate2D(), type: .empty) }
            + categories.ebikeOnlyStations.map { StationAnnotation(coordinate: $0.location.toCLLocationCoordinate2D(), type: .ebikeOnly) }
        }
        
        if let userLocation = locationManager.location {
            updateRegion(to: userLocation.coordinate)
        }
    }
    
    func updateRegion(to coordinate: CLLocationCoordinate2D) {
        region.center = coordinate
        region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    }
}

struct StationAnnotation: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var type: StationType
    
    enum StationType {
        case empty
        case ebikeOnly
    }
}

extension Station.Location {
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
