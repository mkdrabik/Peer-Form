//
//  NotificationsView.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/17/25.
//
//import SwiftUI
//import Supabase
//
//struct NotificationsView: View {
//    @State private var notifications: [NotificationItem] = []
//    @EnvironmentObject var supabaseManager: SupabaseManager
//    @State private var isClearing = false
//    
//    var body: some View {
//        VStack {
//            if notifications.isEmpty {
//                Text("No notifications yet.")
//                    .foregroundColor(.gray)
//                    .padding()
//            } else {
//                List {
//                    ForEach(notifications) { notification in
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(notification.title).bold()
//                            Text(notification.body).font(.subheadline)
//                            Text(notification.created_at)
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                    }
//                    .onDelete(perform: deleteNotification)
//                }
//            }
//        }
//        .navigationTitle("Notifications")
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                if !notifications.isEmpty {
//                    Button(role: .destructive) {
//                        Task { await clearAllNotifications() }
//                    } label: {
//                        if isClearing {
//                            ProgressView()
//                        } else {
//                            Text("Clear All")
//                        }
//                    }
//                }
//            }
//        }
//        .task {
//            await loadNotifications()
//            await markNotificationsAsRead()
//        }
//    }
//
//    func loadNotifications() async {
//        do {
//            let response = try await supabaseManager.client
//                .from("notifications")
//                .select()
//                .eq("user_id", value: supabaseManager.profile?.id ?? "")
//                .order("created_at", ascending: false)
//                .execute()
//
//            let decoded = try JSONDecoder().decode([NotificationItem].self, from: response.data)
//            notifications = decoded.map { noti in
//                var copy = noti
//                let formatter = ISO8601DateFormatter()
//                if let date = formatter.date(from: noti.created_at) {
//                    let displayFormatter = DateFormatter()
//                    displayFormatter.dateStyle = .medium
//                    displayFormatter.timeStyle = .short
//                    displayFormatter.timeZone = TimeZone(identifier: "America/New_York")
//                    copy.created_at = displayFormatter.string(from: date)
//                }
//                return copy
//            }
//        } catch {
//            print("Error loading notifications:", error)
//        }
//    }
//
//    func markNotificationsAsRead() async {
//        do {
//            try await supabaseManager.client
//                .from("notifications")
//                .update(["is_read": true])
//                .eq("user_id", value: supabaseManager.profile?.id ?? "")
//                .execute()
//
//            UIApplication.shared.applicationIconBadgeNumber = 0
//            NotificationCenter.default.post(name: .notificationsRead, object: nil)
//        } catch {
//            print("Error marking notifications as read:", error)
//        }
//    }
//
//    func deleteNotification(at offsets: IndexSet) {
//        Task {
//            for index in offsets {
//                let notification = notifications[index]
//                do {
//                    try await supabaseManager.client
//                        .from("notifications")
//                        .delete()
//                        .eq("id", value: notification.id)
//                        .execute()
//                } catch {
//                    print("Error deleting notification:", error)
//                }
//            }
//            notifications.remove(atOffsets: offsets)
//        }
//    }
//
//    func clearAllNotifications() async {
//        guard !isClearing else { return }
//        isClearing = true
//        do {
//            try await supabaseManager.client
//                .from("notifications")
//                .delete()
//                .eq("user_id", value: supabaseManager.profile?.id ?? "")
//                .execute()
//            notifications.removeAll()
//        } catch {
//            print("Error clearing notifications:", error)
//        }
//        isClearing = false
//    }
//}
//
//struct NotificationItem: Identifiable, Decodable {
//    let id: UUID
//    var title: String
//    var body: String
//    var created_at: String
//}
//
//extension Notification.Name {
//    static let notificationsRead = Notification.Name("notificationsRead")
//}
import SwiftUI
import Supabase

struct NotificationsView: View {
    @State private var notifications: [NotificationItem] = []
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var isClearing = false

    var body: some View {
        List {
            ForEach(notifications) { notification in
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.headline)
                    Text(notification.body)
                        .font(.subheadline)
                    Text(notification.created_at)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteNotification)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !notifications.isEmpty {
                            Button(role: .destructive) {
                                Task { await clearAllNotifications() }
                            } label: {
                                if isClearing {
                                    ProgressView()
                                } else {
                                    Text("Clear All")
                                }
                            }
                        }
                    }
                }
        .task {
            await loadNotifications()
            await markNotificationsAsRead()
        }
    }

    func loadNotifications() async {
        do {
            let response = try await supabaseManager.client
                .from("notifications")
                .select()
                .eq("user_id", value: supabaseManager.profile?.id ?? "")
                .order("created_at", ascending: false)
                .execute()

            let data = response.data
            let decoded = try JSONDecoder().decode([NotificationItem].self, from: data)
            
            notifications = decoded.compactMap { n in
                var noti = n
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSXXXXX"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = formatter.date(from: n.created_at) {
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateStyle = .medium
                    displayFormatter.timeStyle = .short
                    displayFormatter.timeZone = TimeZone(identifier: "America/New_York")
                    noti.created_at = displayFormatter.string(from: date)
                }
                return noti
            }
        } catch {
            print("❌ Error loading notifications:", error)
        }
    }

    func markNotificationsAsRead() async {
        do {
            try await supabaseManager.client
                .from("notifications")
                .update(["is_read": true])
                .eq("user_id", value: supabaseManager.profile?.id ?? "")
                .execute()

            UIApplication.shared.applicationIconBadgeNumber = 0
            NotificationCenter.default.post(name: .notificationsRead, object: nil)
        } catch {
            print("❌ Error marking notifications as read:", error)
        }
    }

    func deleteNotification(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let notification = notifications[index]
                do {
                    try await supabaseManager.client
                        .from("notifications")
                        .delete()
                        .eq("id", value: notification.id)
                        .execute()

                    await MainActor.run {
                        notifications.remove(atOffsets: offsets)
                    }
                } catch {
                    print("❌ Error deleting notification:", error)
                }
            }
        }
    }
    
        func clearAllNotifications() async {
            guard !isClearing else { return }
            isClearing = true
            do {
                try await supabaseManager.client
                    .from("notifications")
                    .delete()
                    .eq("user_id", value: supabaseManager.profile?.id ?? "")
                    .execute()
                notifications.removeAll()
            } catch {
                print("Error clearing notifications:", error)
            }
            isClearing = false
        }
}

struct NotificationItem: Identifiable, Decodable {
    let id: UUID
    var title: String
    var body: String
    var created_at: String
}

extension Notification.Name {
    static let notificationsRead = Notification.Name("notificationsRead")
}
