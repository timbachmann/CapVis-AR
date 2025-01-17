//
//  Home.swift
//  CapVis-AR
//
//  Created by Tim Bachmann on 27.01.22.
//

import SwiftUI
import MapKit
import ARKit
import OpenAPIClient

/**
 Main Tab displaying a full sized map and controls to navigate to gallery, camera view and some map options.
 */
struct MapTab: View {
    
    private let buttonSize: CGFloat = 48.0
    private let buttonOpacity: CGFloat = 0.95
    @EnvironmentObject var imageData: ImageData
    @EnvironmentObject var locationManagerModel: LocationManagerModel
    @EnvironmentObject var settingsModel: SettingsModel
    @Binding var selectedTab: ContentView.Tab
    @State private var showFavoritesOnly = false
    @State private var mapStyleSheetVisible: Bool = false
    @State private var locationButtonCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var detailId: String = ""
    @State private var showGallery: Bool = false
    @State private var showFilter: Bool = false
    @State private var locationManager = CLLocationManager()
    @State private var trackingMode: MKUserTrackingMode = .follow
    @State private var mapType: MKMapType = .standard
    @State private var showDetail: Bool = false
    @State private var uploadProgress = 0.0
    @State private var showUploadProgress: Bool = false
    @State private var zoomOnLocation: Bool = false
    @State private var changeMapType: Bool = false
    @State private var applyAnnotations: Bool = false
    @State private var showCamera: Bool = false
    @State private var includePublic: Bool = false
    @State private var radius: Double = 2.0
    @State private var startDate: Date = Date(timeIntervalSince1970: -3155673600.0)
    @State private var endDate: Date = Date()
    @State private var coordinateRegion = MKCoordinateRegion.init(center: CLLocationCoordinate2D(latitude: CLLocationManager().location?.coordinate.latitude ?? 47.559_601, longitude: CLLocationManager().location?.coordinate.longitude ?? 7.588_576), span: MKCoordinateSpan(latitudeDelta: 0.0051, longitudeDelta: 0.0051))
    
    var body: some View {
        NavigationView {
            ZStack {
                MapView(mapMarkerImages: $imageData.explorerImages, navigationImage: $imageData.navigationImage, selectedTab: $selectedTab, showDetail: $showDetail, detailId: $detailId, zoomOnLocation: $zoomOnLocation, changeMapType: $changeMapType, applyAnnotations: $applyAnnotations, region: coordinateRegion, mapType: mapType, showsUserLocation: true, userTrackingMode: .follow)
                    .edgesIgnoringSafeArea(.top)
                    .onChange(of: imageData.explorerImages) { tag in
                        applyAnnotations = true
                        createNotifications()
                    }
                
                VStack {
                    HStack {
                        if $settingsModel.userThumbRight.wrappedValue == true {
                            Spacer()
                        }
                        VStack(alignment: .leading) {
                            VStack(spacing: 0) {
                                Button(action: {
                                    mapStyleSheetVisible = !mapStyleSheetVisible
                                }, label: {
                                    Image(systemName: "map")
                                        .padding()
                                        .foregroundColor(Color.accentColor)
                                })
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                .cornerRadius(10.0, corners: [.topLeft, .topRight])
                                
                                Divider()
                                    .frame(width: buttonSize)
                                    .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                
                                Button(action: {
                                    requestZoomOnLocation()
                                }, label: {
                                    Image(systemName: "location")
                                        .padding()
                                        .foregroundColor(Color.accentColor)
                                })
                                .clipShape(Rectangle())
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                
                                Divider()
                                    .frame(width: buttonSize)
                                    .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                
                                NavigationLink(destination: GalleryView(selectedTab: $selectedTab), isActive: $showGallery) {
                                    EmptyView()
                                }
                                
                                Button(action: {
                                    $showGallery.wrappedValue.toggle()
                                }, label: {
                                    Image(systemName: "square.grid.2x2")
                                        .padding()
                                        .foregroundColor(Color.accentColor)
                                })
                                .clipShape(Rectangle())
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                
                                Divider()
                                    .frame(width: buttonSize)
                                    .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                
                                Button(action: {
                                    if !$imageData.localFilesSynced.wrappedValue {
                                        syncLocalFiles()
                                    }
                                }, label: {
                                    if $imageData.localFilesSynced.wrappedValue {
                                        Image(systemName: "checkmark.icloud")
                                            .padding()
                                            .foregroundColor(Color.accentColor)
                                    } else {
                                        Image(systemName: "arrow.counterclockwise.icloud")
                                            .padding()
                                            .foregroundColor(Color.accentColor)
                                    }
                                })
                                .clipShape(Rectangle())
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                
                                Divider()
                                    .frame(width: buttonSize)
                                    .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                
                                Button(action: {
                                    $showFilter.wrappedValue.toggle()
                                }, label: {
                                    if $isLoading.wrappedValue {
                                        ProgressView()
                                            .padding()
                                            .foregroundColor(Color.accentColor)
                                    } else {
                                        Image(systemName: "text.magnifyingglass")
                                            .padding()
                                            .foregroundColor(Color.accentColor)
                                    }
                                })
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Color(UIColor.systemBackground).opacity(buttonOpacity))
                                .cornerRadius(10.0, corners: [.bottomLeft, .bottomRight])
                            }
                            Spacer()
                                .frame(height: 24)
                            Button(action: {
                                $showCamera.wrappedValue.toggle()
                            }, label: {
                                Image(systemName: "camera")
                                    .padding()
                                    .foregroundColor(Color.accentColor)
                            })
                            .frame(width: 48.0, height: 48.0)
                            .background(Color(UIColor.systemBackground).opacity(0.95))
                            .cornerRadius(10.0, corners: [.bottomLeft, .bottomRight, .topLeft, .topRight])
                            Spacer()
                        }
                        .padding(8.0)
                        
                        if $settingsModel.userThumbRight.wrappedValue != true {
                            Spacer()
                        }
                    }
                    if $showUploadProgress.wrappedValue {
                        ZStack {
                            Color(UIColor.systemBackground)
                            HStack {
                                ProgressView(value: uploadProgress)
                                    .padding()
                                Image(systemName: "icloud.and.arrow.up")
                            }
                            .padding()
                        }
                        .frame(height: 32)
                    }
                }
                
                NavigationLink(destination: CameraView(), isActive: $showCamera) {
                    EmptyView()
                }
                
                NavigationLink(destination: DetailView(imageIndex: imageData.explorerImages.firstIndex(where: {$0.id == detailId}), selectedTab: $selectedTab), isActive: $showDetail) {
                    EmptyView()
                }
                
                
                if $mapStyleSheetVisible.wrappedValue {
                    ZStack {
                        Color(UIColor.systemBackground)
                        VStack {
                            Text("Map Style")
                            Spacer()
                            Picker("", selection: $mapType) {
                                Text("Standard").tag(MKMapType.standard)
                                Text("Satellite").tag(MKMapType.satellite)
                                Text("Flyover").tag(MKMapType.hybridFlyover)
                                Text("Hybrid").tag(MKMapType.hybrid)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .font(.largeTitle)
                            .onChange(of: mapType) { tag in
                                applyMapTypeChange()
                            }
                        }.padding()
                    }
                    .frame(width: 300, height: 100)
                    .cornerRadius(20).shadow(radius: 20)
                }
                
                if $showFilter.wrappedValue {
                    FilterView(showSelf: $showFilter, isLoading: $isLoading, startDate: $startDate, endDate: $endDate, radius: $radius, includePublic: $includePublic)
                        .frame(width: 350, height: 450)
                        .cornerRadius(20).shadow(radius: 20)
                        .edgesIgnoringSafeArea(.top)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationViewStyle(.stack)
        .edgesIgnoringSafeArea(.top)
        .onAppear(perform: {
            requestNotificationAuthorization()
        })
    }
}

extension MapTab {
    
    /**
     Called if new map type is selected and requests change on map by changing state variable
     */
    func applyMapTypeChange() {
        changeMapType = true
        mapStyleSheetVisible = false
        MKMapView.appearance().mapType = mapType
    }
    
    /**
     Called if location button is pressed and requests zoom on map by changing state variable.
     */
    func requestZoomOnLocation() {
        zoomOnLocation = true
        let span: Double = locationButtonCount % 2 == 0 ? 0.005001 : 0.005002
        coordinateRegion = MKCoordinateRegion.init(center: CLLocationCoordinate2D(latitude: CLLocationManager().location?.coordinate.latitude ?? 47.559_601, longitude: CLLocationManager().location?.coordinate.longitude ?? 7.588_576), span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
        locationButtonCount += 1
    }
    
    /**
     Called if sync with server button is pressed and displays a progress bar while sending new image request to server.
     */
    func syncLocalFiles() {
        let progFrac: Double = (1.0/Double(imageData.imagesToUpload.count))
        showUploadProgress = true
        
        for newImage in imageData.imagesToUpload {
            
            let newImageRequest = NewImageRequest(userID: UIDevice.current.identifierForVendor!.uuidString, id: newImage.id, data: newImage.data, lat: newImage.lat, lng: newImage.lng, date: newImage.date, source: newImage.source, bearing: newImage.bearing, yaw: newImage.yaw, pitch: newImage.pitch, publicImage: newImage.publicImage)
            
            uploadProgress += progFrac/2
            
            ImageAPI.createImage(newImageRequest: newImageRequest) { (response, error) in
                guard error == nil else {
                    print(error ?? "error")
                    return
                }
                
                if (response != nil) {
                    dump(response)
                    imageData.imagesToUpload.remove(at: imageData.imagesToUpload.firstIndex(of: newImage)!)
                    uploadProgress += progFrac/2
                    imageData.localFilesSynced = imageData.imagesToUpload.isEmpty
                    showUploadProgress = !imageData.imagesToUpload.isEmpty
                    imageData.saveImagesToFile()
                    if (imageData.localFilesSynced) {
                        uploadProgress = 0.0
                    }
                }
            }
        }
    }
    
    /**
     Schedules notifications for all images with a location trigger.
     */
    func createNotifications() {
        
        for image in imageData.explorerImages {
            let notificationIdentifier = image.id + "_" + "capvisar"
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
            
            let location = CLLocation(latitude: image.lat, longitude: image.lng)
//            let distance = CLLocationManager().location?.distance(from: location)
            
            
            let content = UNMutableNotificationContent()
            content.title = "Photo in Range"
            content.subtitle = "Click to view in AR"
            content.body = String(format: "50m")
            content.sound = UNNotificationSound.default
            content.badge = 1
            content.categoryIdentifier = "capVisAR"
            content.userInfo = ["customDataKey": "cusom_data_value"]
            
            // 2. Create Trigger and Configure the desired behaviour - Location
            let region = CLCircularRegion(center: location.coordinate, radius: 50.0, identifier: UUID().uuidString)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
            let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
            let attachment = try! UNNotificationAttachment(identifier: "image" + image.id, url: getCacheDirectoryPath().appendingPathComponent(image.id).appendingPathComponent("\(image.id)-thumb.jpg"))
            content.attachments = [attachment]
            
            // 3. Create the Request
            UNUserNotificationCenter.current().add(request) { error in
                
                guard error == nil else { return }
                
                print("Notification scheduled! — ID = \(image.id)")
            }
            
        }
    }
    
    /**
     Returns cache directory path
     */
    func getCacheDirectoryPath() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    /**
     Requests authorization to send notifications
     */
    func requestNotificationAuthorization() {
        
        let nc = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        nc.requestAuthorization(options: options) { granted, _ in
            print("\(#function) Permission granted: \(granted)")
            guard granted else { return }
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        MapTab(selectedTab: .constant(.home))
            .environmentObject(ImageData())
    }
}

/**
 Struct to represent a rectangle with rounded corners
 */
struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    
    /**
     View extension to apply the rounded corner struct to any view.
     */
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

//extension MKCoordinateRegion: Equatable {
//
//    /**
//
//     */
//    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
//        if lhs.center.latitude == rhs.center.latitude && lhs.span.latitudeDelta == rhs.span.latitudeDelta && lhs.span.longitudeDelta == rhs.span.longitudeDelta {
//            return true
//        } else {
//            return false
//        }
//    }
//}

extension UINavigationController: UIGestureRecognizerDelegate {
    
    /**
     Add pop gesture recognizer to UINavigationController to recognize swipe back gestures
     */
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    /**
     Gesture reognizer should be active if there is more than one view controller.
     */
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
