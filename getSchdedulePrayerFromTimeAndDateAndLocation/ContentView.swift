import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var currentDate: String = ""
    @State private var currentTime: String = ""
    @State private var currentProvince: String = "Unknown"
    @State private var currentCity: String = "Unknown"
    @State private var prayerTime: String = "Loading..."
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Province: \(currentProvince)")
                .font(.title)
                .padding()
            Text("City: \(currentCity)")
                .font(.title)
                .padding()
            Text("Current Date: \(currentDate)")
                .font(.title)
                .padding()
            Text("Current Time: \(currentTime)")
                .font(.largeTitle)
                .padding()
            Text(prayerTime)
                .font(.title)
                .padding()
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onReceive(locationManager.$province) { province in
            currentProvince = province
            updatePrayerTime()
        }
        .onReceive(locationManager.$city) { city in
            currentCity = city
            updatePrayerTime()
        }
    }
    
    private func startTimer() {
        updateTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTime()
        }
    }
    
    private func updateTime() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        currentDate = dateFormatter.string(from: Date())
        
        dateFormatter.dateFormat = "HH:mm:ss"
        currentTime = dateFormatter.string(from: Date())
    }
    
    private func updatePrayerTime() {
        guard let location = locationManager.location else {
            print("Location not available")
            return
        }
        
        if let prayerTimes = loadPrayerTimes(for: Date(), province: currentProvince, city: currentCity) {
            prayerTime = getNextPrayerTime(currentTime: Date(), prayerTimes: prayerTimes)
        } else {
            prayerTime = "Error loading prayer times"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
