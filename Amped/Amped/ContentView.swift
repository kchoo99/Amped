//
//  ContentView.swift
//  Amped
//
//  Created by 0x7B5 on 8/8/23.
//

import SwiftUI
import MapKit
import CoreLocation
import FirebaseCore
import PartialSheet

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

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
    @State private var ebikeOnlyCount: Int = 0
    @State private var emptyCount: Int = 0
    @State private var lastUpdateTime: Date? = nil
    @State private var initialRegionSet = false
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    
    @State private var annotations: [StationAnnotation] = []
    @State private var isLoading: Bool = false
    @State private var dataRefreshTimer: Timer? = nil
    @State private var isSettingsSheetVisible: Bool = false
    @State private var optionOneEnabled: Bool = false
    @State private var optionTwoEnabled: Bool = false
    
    var lastUpdateTimeString: String {
        guard let lastUpdate = lastUpdateTime else { return "00:00" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: lastUpdate)
    }
    
    
    
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
            .onAppear(perform: {
                loadData()
                setupDataRefreshTimer()
            })
            .onDisappear(perform: invalidateDataRefreshTimer)
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
                .foregroundColor(Color.black)
                .background(Color.white.opacity(1.0))
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
                            .fill(Color.white.opacity(0.95))
                    )
                    .padding(.leading, 16)
                    
                    Spacer()

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
                                Text("Ebikes Only: \(ebikeOnlyCount)")
                                    .font(.footnote)
                                    .foregroundColor(Color.black)
                            }
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 20, height: 20)
                                Text("Empty Docks: \(emptyCount)")
                                    .font(.footnote)
                                    .foregroundColor(Color.black)
                            }
                        Text("Last updated: \(lastUpdateTimeString)")
                            .font(.footnote)
                            .foregroundColor(Color(.darkGray))
                        }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 5)
                    .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white.opacity(0.95))
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
                                    .fill(Color.white.opacity(0.95))
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
                            isSettingsSheetVisible = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.95))
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
        .partialSheet(isPresented: $isSettingsSheetVisible) {
            VStack {
                            Text("Settings")
                                .font(.headline)
                                .padding(.top)
            
                            Toggle("Option 1", isOn: $optionOneEnabled)
                                .padding()
            
                            Toggle("Option 2", isOn: $optionTwoEnabled)
                                .padding()
            
                        }
                        .padding(.horizontal)
             }
    }
    
    func setupDataRefreshTimer() {
        dataRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            // Fetch the data silently
            loadData(silently: true)
        }
    }

    func invalidateDataRefreshTimer() {
        dataRefreshTimer?.invalidate()
        dataRefreshTimer = nil
    }
    
    func loadData(silently: Bool = false) {
        print("Loading data")
        if !silently {
            isLoading = true
        }
        
        let api = CitibikeAPI()
        
        api.fetchStations { stations in
            if !silently {
                isLoading = false
            }
            
            let categories = api.categorizeStations(stations: stations)
            
            annotations = categories.emptyStations.map { StationAnnotation(coordinate: $0.location.toCLLocationCoordinate2D(), type: .empty) }
            + categories.ebikeOnlyStations.map { StationAnnotation(coordinate: $0.location.toCLLocationCoordinate2D(), type: .ebikeOnly) }
            
            ebikeOnlyCount = categories.ebikeOnlyStations.count
            emptyCount = categories.emptyStations.count
            self.lastUpdateTime = Date()
        }
        
//        if let userLocation = locationManager.location {
//            updateRegion(to: userLocation.coordinate)
//        }
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
        ContentView().attachPartialSheetToRoot()
    }
    
}
