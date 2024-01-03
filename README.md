# DISASTER_MESSAGE_APP
🌊 재난문자 푸시 알림 구현
지난시간에 UNNotificationCenter에 UNNotificationRequest를 등록해서 local Notification을 구현했다.

이번 시간에는 반대로 Remote Notification을 구현해보려고 한다. 우리가 받는 알림 중에 대부분은 정해진 시간에 동일한 문구로 전달되는 local Notification이 아니라, remote notification일 가능성이 높다!

### **🤦🏻 개발자님, 우리 VIP 사용자들을 선별해서 40% 할인 쿠폰을 발급하려고 해요. 쿠폰 보내면 도착 알림 보내주세요! 어떻게 하냐고요?! 저야 모르죠!!**

### **🙋🏻‍♂️ 개발자님! 내가 팔로우하는 사용자가 나를 태그했을 때 확인해보라는 알림을 보낼거예요. 개발하실 수 있으시죠?**

### **🤦🏼‍♂️ 코로나19 비상! 확진자 및 밀접 접촉자가 불특정 시간에 불특정 인원이 불특성 장소에서 발생하고 있어요! 국민의 안전을 위해 본부에서 확인 즉시 경보 메세지를 보내려고 합니다.**

다음과 같은 상황에서 사용할 수 있는 것이 바로 remote notification이다. 위의 상황들은 모두 local notification 만으로는 충분하지 않고, 예측도 불가능 하기 때문에 미리 코드로 static한 문구를 작성해 놓을 수 없다! 결국 remote notification , 말 그대로 ***[원격 알림]***이 필요하다

원격알림은 서비스의 서버, 백엔드에서 특정 시점에 발송할 수 있다.

local 알림은 기기 내에서 UNNotificationCenter를 통해 알림 설정, 관리, 전송이 가능했다면

원격 알림은 Provider(즉 자체 서버)가 있어야 한다.

그리고 또 하나의 과정을 더 거치는데, 바로 APNs 라는 과정이 필요하다.

## 🔔 APNS에 대해

***APNs (Apple Push Notification Service)***

원격 알림을 사용할 때 반드시 거쳐야 하는 핵심 과정이다.

서버에서 바로 기기로 알림을 보내지 않고, 반드시 이 APNs를 거치게 해야 하는데

그 이유가 무엇일까?

APNs에는 저장 후에 전달 기능을 수행하는 QOS 구성요소가 포함되어 있다.

먼저 APNs가 알림 전달을 (기기로) 시도하고, 알림을 전달받을 대상 장치가 오프라인인 경우에는 APNs에서 제한된 시간동안 알림을 저장하고 장치를 다시 사용할 수 있게 즉 온라인 상태로 바뀌면 전달을 하게 된다.

또 APNs는 기기 및 앱 별로 가장 최근에 알림만 저장을 한다.

각 앱 서비스의 서버에서 보내는 각종 알림들을 최신 상태로 하나씩 저장하다,  장치가 너무 오랫동안 오프라인 상태를 유지하면 저장된 모든 알림을 삭제하는 방식으로 관리한다.

이렇게 단순히 알림을 보내고 끝내는 것이 아니라, 각 기기의 상태를 확인하여 상태에 따라서 알림을 저장 후에 보내주고 또 최신의 알림 상태를 관리하는 등의 관리센터 역할을 하는 것이 바로 이 APNs이다.

두 번째 APNs의 역할은 ‘보안’이다.

네트워크로 전달되는 데이터의 경우, 보안 문제에 항상 노출된다. 제 3자에 의해 데이터가 탈취될 수 있기 때문에 

알림을 보내는 provider가 전혀 의도하지 않은 메세지로 변환되어, 오염된 상태로 기기에 전달될 수도 있다.

이러한 보안 문제를 해결하기 위해 APNs는 자체 보안 Architecture를 통해서 원격 알림을 안전하게 제어한다.

이렇게 보안을 유지하기 위해 두 가지의 신뢰수준을 사용한다.

### Connection trust (연결신뢰) :

 ***Provider - APNs 간의 신뢰*** | Apple과 계약을 맺은 회사가 소유한 승인된 공급자만 APNs와 연결을 해서 푸쉬 알림 전달을 할 수 있게 해서 연결 신뢰 구성

→ 즉 공급자 서버는 APNs와의 Connection Trust가 있는지 확인하는 단계를 수행해야 한다. →확인방법

- token-based : 유효한 인증키를 이용해서 확인
- certificate-based : 인증서 기반 connection trust (SSL 인증서 이용)

보통 해당 작업은 푸시 알림 서버를 구현하는 백엔드 개발자가 담당!

***APNs - Device 간의 신뢰*** | 승인된 장치만 APNs에 연결해서 알림을 받을 수 있도록 하는 것이다.

APNs는 이 부분에 대해 각 장치와 Connection Trust를 자동으로 적용해서 안전성을 보장해준다.

### Device token trust :

각 원격 알림에서 end to end로 동작

즉 알림이 올바른 시작(Provider)와 올바른 장치, 이 두 가지 지점 사이에서만 라우팅 되도록 하는 것이다.

Device token은 Apple이 특정 장치의 특정 앱에 할당한 고유 식별자를 포함하는 NSData 인스턴스이다.

설령 이 토큰을 누군가 탈취를 하더라도 내용을 이해할 수 없다. 오직 APNs만 이 장치 토큰의 내용을 해독하고 이해할 수 있다.(멋있다)

따라서 각 앱은 원격 알림을 사용하기 위해서 APNs에 등록을 하게 되고, 이때 고유한 device token을 갖게 된다. 그 다음 해당 Provider에게 토큰을 전달하고, Provider는 연결된 장치를 대상으로 하는 각각의 Push 알림 요청에 장치 토큰을 포함한 채 전달해야 한다(그래야 확인을 하지)

APNs는 여러 상황에서 이런 디바이스 토큰을 새로 발급할 수 있다. 예를 들면 새 기기에서 동일한 앱을 설치하거나, 백업으로 복원하거나, OS를 업데이트 할 때 등 디바이스와 앱의 상태가 변경되었을 때, 새로 발습해서 항상 고유한 상태를 바라보게 한다.  

## ☁ Firebase Cloud Messaging 알아보기

앞서 말한 APNs 보안 요건을 갖춘 서버를 직접 구현하기 힘들 때, iOS client 개발자로써 서비스와 앱 자체에만 집중하고 싶을 때 손쉽게 원격 알림을 보낼 수 있도록 도와주는 도구이다.

Provider 즉 서버의 역할을 이 FCM이 대신해주는 것이다.

Remote notification을 손쉽게 관리하고 보낼 수도 있는 firebase의 플랫폼이다.

예전에 A_B Testing을 공부할 때 본 적이 있는데, 

A_B Testing을 하는 방법으로 RemoteConfig(원격 구성)과 Cloud Messaging이 있었다.

구글 애널리틱스 기반으로 사용자를 타겟팅해서 해당 타겟에만 원격구성을 할 수도 있고 알림을 보낼 수도 있는 것이다. 

보냈던 메세지를 저장하고 얼마나 확인했는지도 파악할 수도 있고 (사용자 중 이 메세지를 확인한 비율)

FCM을 통해 보낸 알림들을 웹 콘솔을 활용해 편리하게 관리할 수 있다.

# 구현

## FCM 설정하기

이제는 익숙하게 Firebase에 들어가서 프로젝트를 만들고(이름은 Warning, 구글 애널리틱스를 ON)

<img width="1792" alt="0" src="https://github.com/jinyongyun/DISASTER_MESSAGE_APP/assets/102133961/9db9d1f1-784e-41db-82e7-41a505f52a39">


iOS+ 버튼을 눌러 내 앱에 Firebase를 등록한다. BundleID를 넣어주고 GoogleService-info 파일을 내 프로젝트에 넣어준다.

pod 'Firebase/Analytics'
pod 'Firebase/Messaging'

다음 두 개를 생성한 pod 파일에 추가한 뒤, pod install

워크스페이스로 가서

AppDelegate에서 Firebase를 초기화

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        return true
    }
```

(여기까진 굉장히 익숙, 이젠 루틴이라고도 할 수 있다)

## APNs 구성하기

우리가 애플 기기에 원격알림을 보내려면 반드시 거쳐야한다고 했다.

이 APNs에 우리 앱이 원격 알림 쓸거야라고 등록하고 키를 받아야 한다.

Project > Signing&Capabilities > +Capability > Push 검색 

이렇게 하면 Signing Certificate이 만들어진다! (Apple Developer에 등록되어 있어야 함)

Apple Developer에 들어가서 Overview에 Certificates, Identifiers & Profiles로 들어간다.

좌측에 Keys를 선택한다.(들어가서 + 버튼)

Register a New Key를 선택해서 Key를 등록하면 된다.

![1](https://github.com/jinyongyun/DISASTER_MESSAGE_APP/assets/102133961/3fba45d8-cc80-48cc-94df-6e598005801f)


APNs 항목에 체크한다음 Continue > Register 버튼을 차례로 누른다.

우리가 입력한 Key 이름과 함께 Key ID가 만들어진다.

이 ID를 복사하고 Download 까지 해준다. 

Download를 한 번 하면 그 이후로 버튼이 비활성화 되는데

꼭 잘 저장해놓자

이제 Firbase 콘솔로 가서 (Warning 프로젝트로 이동)

톱니바퀴 아이콘 > 프로젝트 설정 > 클라우드 메세징 으로 이동한다.

<img width="1792" alt="2" src="https://github.com/jinyongyun/DISASTER_MESSAGE_APP/assets/102133961/e974840d-e85a-4335-80cd-eec891658407">


 APN 인증 키 영역에서 업로드를 클릭하고, 찾아보기를 누른 후

우리가 다운로드 했던 키를 선택한 뒤 업로드를 한다.

key ID 항목에는 복사했던 Key ID를 입력하고

팀 ID는 Apple Developer 콘솔로 다시 이동 > Membership 으로 가면 TeamID가 나온다.

이것까지 완료하면 APNs를 사용하기 위한 사전 작업이 완료됐다.

## Firebase 연결하기

지난번 UserNotification을 만들었던 때와 비슷하게 

원격알림을 받을 수 있도록 AppDelegate에 UserNotification을 설정하겠다.

```swift
func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self //밑에다 추가해도 괜찮지만 그냥 구분을 위해 여기서
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //알림 권한 설정
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound] //기기에 알림 승인을 위해
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, error in
            print("ERROR, Request Notifications Authorization: \(error.debugDescription)")
        }
        application.registerForRemoteNotifications()
        
        
        FirebaseApp.configure()
        return true
    }
```

### willFinishLauchingWithOptions 작업을 끝내면 Delegate를 구현하라고 에러가 뜬다.

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    //원격으로 받은 Notification의 Display 형태를 지정해줘야 한다.
    //iOS 10 이후부터는 알림의 형태를 알림센터 / 배너 / 뱃지 / 소리 로 구분하여 어떻게 표시할 지 설정가능
    //해당 설정의 기본 값 지정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .badge, .sound])
    }
    
}
```

extension을 통해 구현해주도록 하자. 

원격으로 받은 Notification의 Display 형태를 지정해주는 과정이다.

## Remote Notification 구성하기

메세지 델리게이트를 설정할건데

기본적으로 FCM SDK는 앱을 시작할 때 ‘클라이언트 앱 인스턴스 용 등록 토큰’을 생성한다.

앞서서 APNs도 보안을 위해 디바이스 토큰을 생성한다고 한 것과 같이 

FCM도 자체 토큰을 사용해 타겟팅한 알림을 앱의 모든 특정 인스턴스로 전송할 수 있다.

iOS가 일반적으로 앱 시작할 때 APNs 디바이스 토큰을 전달하는 것과 마찬가지로 

FCM은 FIR 메세징 델리게이트 메서드를 통해 [등록 토큰]이라는 것을 제공한다.

FCM이 이러한 등록 토큰 기반으로 접근할 수 있도록 코드 작업을 해주자.

```swift
import FirebaseMessaging
//...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //...
        Messaging.messaging().delegate = self // 이녀석 추가

        //FCM 현재 등록 토큰 확인
        Messaging.messaging().token { token, error in
            if let error = error {
                print("ERROR FCM 등록토큰 가져오기: \(error.localizedDescription)")
            } else if let token = token {
                print("FCM 등록토큰: \(token)")
            }
        }

        //...
    }

extension AppDelegate: MessagingDelegate {
    //토큰이 갱신되는 시점 확인
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {return}
        print("FCM 등록토큰 갱신: \(token)")
    }
}
```

원격 알림은 시뮬레이터에서 테스트를 지원하지 않기 때문에 실제 기기를 연결해야 토큰이 등록되고, 토근 번호를 확인할 수 있다.

터미널에 찍힌 토큰을 복사한다.

Firebase 콘솔로 이동해, 참여 섹션에 Cloud Messaging으로 이동한다.(현재 Messagin으로 바뀜, 들어가서 메세지 유형을 Firebase 알림 메세지로 선택하면 Cloud Messaging이 된다)

<img width="1783" alt="3" src="https://github.com/jinyongyun/DISASTER_MESSAGE_APP/assets/102133961/218204c4-9742-47c3-ba1b-f80499cb92ec">


알림 정보를 입력하면 ‘테스트 메세지 전송’ 버튼이 활성화되는데 

들어가면 [FCM 등록 토큰 추가] 항목이 있다. 아까 터미널에서 복사한 토큰을 여기에 불어넣기 한다.

테스트 버튼을 클릭하면 연결된 실제 테스트 기기에 수 초 안으로 알림을 도착하는 것을 볼 수 있다.

이제 특정 테스트 기기가 아닌 해당 앱을 사용하는 전체 사용자에게 알림을 보내보도록 하자

지금은 이 앱을 우리만 사용하고 있어서 별 차이는 없겠지만, 만약 이 앱을 앱스토어에 배포하고 

불특정 다수의 사용자가 이 앱을 사용하고 있다면 다를 것이다.

재난문자 내용을 알림에 작성하고 다음을 누르면 타겟을 설정할 수 있다.

지난 번에 만든 remote config와 마찬가지로 사용자 타겟을 구분지어서 정할 수 있다.

우리는 전체 사용자에게 보낼 것이기에 타겟팅을 따로 해주지는 않겠다.

그 다음은 예약 항목인데, 말 그대로 특정 시점에 알림을 보내줄 수 있다. (지금으로 설정)

전환 이벤트나 추가 옵션은 생략하고 검토 후 게시를 누른다.

이렇게 하면 수 분 내로 방금 작성한 재난문자알림이 기기로 전달되는 것을 확인할 수 있다.

이런 식으로 왔다.

![4](https://github.com/jinyongyun/DISASTER_MESSAGE_APP/assets/102133961/cf0614a3-f23d-4d75-9d04-5dc5f5ac549a)
