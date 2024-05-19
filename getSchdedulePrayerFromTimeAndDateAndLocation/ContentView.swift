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
    @State private var countdown: String = ""
    
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
            Text("Countdown: \(countdown)")
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
            updateCountdown()
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
            updateCountdown(prayerTimes: prayerTimes)
        } else {
            prayerTime = "Error loading prayer times"
        }
    }
    
    private func updateCountdown(prayerTimes: PrayerTimes? = nil) {
        guard let location = locationManager.location else {
            print("Location not available")
            return
        }
        
        let now = Date()
        var nextPrayerDate: Date? = nil
        
        if let prayerTimes = prayerTimes ?? loadPrayerTimes(for: now, province: currentProvince, city: currentCity) {
            nextPrayerDate = getNextPrayerDate(currentTime: now, prayerTimes: prayerTimes)
        }
        
        if let nextPrayerDate = nextPrayerDate {
            let remainingSeconds = Int(nextPrayerDate.timeIntervalSince(now))
            countdown = formatSecondsToTimeString(remainingSeconds)
        } else {
            countdown = "Error calculating countdown"
        }
    }
    
    private func getNextPrayerDate(currentTime: Date, prayerTimes: PrayerTimes) -> Date? {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        func timeToComponents(_ time: String) -> DateComponents? {
            guard let date = dateFormatter.date(from: time) else { return nil }
            return calendar.dateComponents([.hour, .minute], from: date)
        }
        
        func createDate(components: DateComponents) -> Date? {
            return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: currentTime)
        }
        
        let prayerTimesList = [
            prayerTimes.fajr,
            prayerTimes.sunrise,
            prayerTimes.dhuhr,
            prayerTimes.asr,
            prayerTimes.maghrib,
            prayerTimes.isha
        ]
        
        for prayerTime in prayerTimesList {
            if let components = timeToComponents(prayerTime), let date = createDate(components: components), date > currentTime {
                return date
            }
        }
        
        // If the current time is past Isha, return the time for Fajr of the next day
        if let fajrComponents = timeToComponents(prayerTimes.fajr), let fajrDate = createDate(components: fajrComponents) {
            return calendar.date(byAdding: .day, value: 1, to: fajrDate)
        }
        
        return nil
    }
    
    private func formatSecondsToTimeString(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
