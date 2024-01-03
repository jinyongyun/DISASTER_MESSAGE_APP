//
//  AppDelegate.swift
//  Warning
//
//  Created by jinyong yun on 1/3/24.
//

import UIKit
import Firebase
import UserNotifications
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self //밑에다 추가해도 괜찮지만 그냥 구분을 위해 여기서
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        //FCM 현재 등록 토큰 확인
        Messaging.messaging().token { token, error in
            if let error = error {
                print("ERROR FCM 등록토큰 가져오기: \(error.localizedDescription)")
            } else if let token = token {
                print("FCM 등록토큰: \(token)")
            }
        }
        
        //알림 권한 설정
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound] //기기에 알림 승인을 위해
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, error in
            print("ERROR, Request Notifications Authorization: \(error.debugDescription)")
        }
        application.registerForRemoteNotifications()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate: UNUserNotificationCenterDelegate {
    //원격으로 받은 Notification의 Display 형태를 지정해줘야 한다.
    //iOS 10 이후부터는 알림의 형태를 알림센터 / 배너 / 뱃지 / 소리 로 구분하여 어떻게 표시할 지 설정가능
    //해당 설정의 기본 값 지정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .badge, .sound])
    }
    
}

extension AppDelegate: MessagingDelegate {
    //토큰이 갱신되는 시점 확인
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {return}
        print("FCM 등록토큰 갱신: \(token)")
    }
}
