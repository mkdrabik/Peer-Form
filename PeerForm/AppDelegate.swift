//
//  AppDelegate.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/14/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import Supabase
import UserNotifications

private struct UserTokenPayload: Encodable {
    let user_id: String
    let fcm_token: String
    let platform: String
}

class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    let supabaseManager = SupabaseManager.shared
    var supabaseClient = SupabaseManager.shared.client
    var fcmToken: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        guard let url = Bundle.main.url(forResource: "SupabaseKeys", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let supabaseURL = plist["url"] as? String,
              let supabaseAnonKey = plist["key"] as? String else {
            fatalError("❌ Missing or invalid SupabaseKeys.plist file")
        }

        supabaseClient = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error:", error)
                return
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("🚫 User denied notification permissions.")
            }
        }

        Messaging.messaging().delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        UIApplication.shared.applicationIconBadgeNumber += 1
        completionHandler([.banner, .sound, .badge])
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Task {
            do {
                let response = try await supabaseClient
                    .from("notifications")
                    .select("id")
                    .eq("user_id", value: supabaseClient.auth.currentUser?.id ?? "")
                    .eq("is_read", value: false)
                    .execute()
                let data = response.data
                let decoded = try JSONDecoder().decode([NotificationItem].self, from: data)
                UIApplication.shared.applicationIconBadgeNumber = decoded.count
            } catch {
                print("Error fetching unread count:", error)
            }
        }
    }


    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("📱 FCM token:", fcmToken)
        Task { await upsertFcmToken(fcmToken) }
    }
    

    func upsertFcmToken(_ token: String) async {
        guard let user = supabaseClient.auth.currentUser else {
            print("⚠️ No authenticated user; skipping token upload.")
            return
        }
        await deleteFcmToken(id: user.id)
        let payload = UserTokenPayload(
            user_id: user.id.uuidString,
            fcm_token: token,
            platform: "ios"
        )
        do {
            let _ = try await supabaseClient
                .from("user_tokens")
                .upsert([payload])
                .execute()
            self.fcmToken = token
            print("✅ FCM token upserted: \(token)")
        } catch {
            print("❌ Failed to upsert FCM token:", error)
        }
    }

    func deleteFcmToken(id: UUID) async {
        do {
            guard let token = self.fcmToken else { print("No token found"); return }
            try await supabaseClient
                .from("user_tokens")
                .delete()
                .eq("user_id", value: id)
                .eq("fcm_token", value: token)
                .execute()
                print("🗑️ Deleted FCM token for user \(id).")
        } catch {
            print("❌ Failed to delete token:", error)
        }
    }
}
