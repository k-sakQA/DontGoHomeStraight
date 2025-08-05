import SwiftUI
import MapKit
import CoreLocation

struct DestinationSettingView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671), // 東京駅
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchText = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress = ""
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            searchBarSection
            
            // 地図
            mapSection
            
            // 選択された目的地情報
            if selectedCoordinate != nil {
                destinationInfoSection
            }
            
            // ナビゲーションボタン
            navigationButtonSection
        }
        .navigationTitle("目的地を設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupInitialRegion()
        }
    }
    
    @ViewBuilder
    private var searchBarSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("目的地を検索（例：渋谷駅）", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        searchLocation()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            if isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("検索中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var mapSection: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: mapAnnotations) { annotation in
                MapPin(coordinate: annotation.coordinate, tint: .red)
            }
            .onTapGesture { location in
                // 地図タップで目的地設定
                let coordinate = region.center
                setDestination(coordinate: coordinate)
            }
            
            // 中央の十字マーク
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.red)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                        )
                    Spacer()
                }
                Spacer()
            }
            
            // 現在地ボタン
            VStack {
                HStack {
                    Spacer()
                    Button(action: centerOnCurrentLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.trailing)
                }
                Spacer()
            }
            .padding(.top, 50)
            
            // 地図操作ガイド
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("地図をタップまたは")
                        Text("中央マークで目的地設定")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(.leading)
                
                Spacer()
            }
            .padding(.top, 10)
        }
        .frame(minHeight: 300)
    }
    
    @ViewBuilder
    private var destinationInfoSection: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("選択された目的地")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(selectedAddress.isEmpty ? "住所を取得中..." : selectedAddress)
                        .font(.body)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .background(Color.blue.opacity(0.1))
    }
    
    @ViewBuilder
    private var navigationButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                confirmDestination()
            }) {
                HStack {
                    Image(systemName: "arrow.right")
                    Text("次へ")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedCoordinate != nil ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(selectedCoordinate == nil)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var mapAnnotations: [MapAnnotation] {
        guard let coordinate = selectedCoordinate else { return [] }
        return [MapAnnotation(coordinate: coordinate)]
    }
    
    // MARK: - Actions
    
    private func setupInitialRegion() {
        if let currentLocation = viewModel.currentLocation {
            region = MKCoordinateRegion(
                center: currentLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    private func centerOnCurrentLocation() {
        guard let currentLocation = viewModel.currentLocation else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: currentLocation,
                span: region.span
            )
        }
    }
    
    private func searchLocation() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    print("Geocoding error: \(error)")
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    return
                }
                
                let coordinate = location.coordinate
                setDestination(coordinate: coordinate)
                
                // 地図をその場所に移動
                withAnimation(.easeInOut(duration: 0.8)) {
                    region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
        }
    }
    
    private func setDestination(coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        
        // 逆ジオコーディングで住所を取得
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error)")
                    selectedAddress = "住所を取得できませんでした"
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let administrativeArea = placemark.administrativeArea {
                        addressComponents.append(administrativeArea)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    if let subLocality = placemark.subLocality {
                        addressComponents.append(subLocality)
                    }
                    if let thoroughfare = placemark.thoroughfare {
                        addressComponents.append(thoroughfare)
                    }
                    
                    selectedAddress = addressComponents.joined(separator: " ")
                    
                    if selectedAddress.isEmpty {
                        selectedAddress = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    }
                }
            }
        }
    }
    
    private func confirmDestination() {
        guard let coordinate = selectedCoordinate else { return }
        
        let destination = Destination(
            name: selectedAddress.isEmpty ? "選択された地点" : selectedAddress,
            coordinate: coordinate,
            address: selectedAddress
        )
        
        viewModel.setDestination(destination)
        viewModel.navigateToTransportModeSelection()
    }
}

// MARK: - Supporting Types

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview

#Preview {
    NavigationView {
        DestinationSettingView(viewModel: AppViewModel.preview)
    }
}

// MARK: - Map Helper Views

struct MapControlsView: View {
    let onCurrentLocationTap: () -> Void
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onCurrentLocationTap) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(radius: 2)
            
            Button(action: onZoomIn) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .frame(width: 44, height: 44)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(radius: 2)
            
            Button(action: onZoomOut) {
                Image(systemName: "minus")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .frame(width: 44, height: 44)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(radius: 2)
        }
    }
}