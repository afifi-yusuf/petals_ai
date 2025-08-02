
import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleDailyCheckIn(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Mood Check-in"
        content.body = "Don't forget to log your mood today!"
        content.sound = .default
        
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyCheckin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func disableDailyCheckIn() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyCheckin"])
    }
}
