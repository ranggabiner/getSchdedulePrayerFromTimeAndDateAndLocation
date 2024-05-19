import Foundation
import CoreLocation

struct PrayerTimes: Decodable {
    let province: String
    let city: String
    let date: String
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
}

func loadPrayerTimes(for location: CLLocation, date: Date) -> PrayerTimes? {
    guard let url = Bundle.main.url(forResource: "prayer_times", withExtension: "json") else {
        print("Error: File not found")
        return nil
    }
    do {
        let data = try Data(contentsOf: url)
        let prayerTimesArray = try JSONDecoder().decode([PrayerTimes].self, from: data)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                print("Error getting placemark: \(error?.localizedDescription ?? "")")
                return
            }
            let province = placemark.administrativeArea ?? ""
            let city = placemark.locality ?? ""
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yy"
            let targetDate = dateFormatter.string(from: date)
            
            guard let prayerTimes = prayerTimesArray.first(where: { $0.province == province && $0.city == city && $0.date == targetDate }) else {
                print("Error: Prayer times not found for \(province), \(city), \(targetDate)")
                return
            }
            print("Prayer times for \(province), \(city), \(targetDate): \(prayerTimes)")
        }
        
        return nil // Return value will be set asynchronously
    } catch {
        print("Error loading JSON: \(error)")
        return nil
    }
}

func getNextPrayerTime(currentTime: Date, prayerTimes: PrayerTimes) -> String {
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    
    func timeToComponents(_ time: String) -> DateComponents? {
        guard let date = dateFormatter.date(from: time) else { return nil }
        return calendar.dateComponents([.hour, .minute], from: date)
    }
    
    guard
        let fajrComponents = timeToComponents(prayerTimes.fajr),
        let sunriseComponents = timeToComponents(prayerTimes.sunrise),
        let dhuhrComponents = timeToComponents(prayerTimes.dhuhr),
        let asrComponents = timeToComponents(prayerTimes.asr),
        let maghribComponents = timeToComponents(prayerTimes.maghrib),
        let ishaComponents = timeToComponents(prayerTimes.isha)
    else {
        print("Error: Invalid prayer times format")
        return "Invalid prayer times"
    }
    
    func createDate(components: DateComponents) -> Date? {
        return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: currentTime)
    }
    
    guard
        let fajrTime = createDate(components: fajrComponents),
        let sunriseTime = createDate(components: sunriseComponents),
        let dhuhrTime = createDate(components: dhuhrComponents),
        let asrTime = createDate(components: asrComponents),
        let maghribTime = createDate(components: maghribComponents),
        let ishaTime = createDate(components: ishaComponents)
    else {
        print("Error: Unable to create dates from components")
        return "Invalid prayer times"
    }
    
    if currentTime >= fajrTime && currentTime < sunriseTime {
        return "Sunrise: \(prayerTimes.sunrise)"
    } else if currentTime >= sunriseTime && currentTime < dhuhrTime {
        return "Dhuhr: \(prayerTimes.dhuhr)"
    } else if currentTime >= dhuhrTime && currentTime < asrTime {
        return "Asr: \(prayerTimes.asr)"
    } else if currentTime >= asrTime && currentTime < maghribTime {
        return "Maghrib: \(prayerTimes.maghrib)"
    } else if currentTime >= maghribTime && currentTime < ishaTime {
        return "Isha: \(prayerTimes.isha)"
    } else {
        return "Fajr: \(prayerTimes.fajr)"
    }
}
