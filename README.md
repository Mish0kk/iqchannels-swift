# IQChannelsSwift
## Список библиотек, используемых в проекте и их назначение

1. **SDWebImageSwiftUI**: Для загрузки и кэширования изображений в SwiftUI.
2. **SQLite.swift**: Для сохранения сообщений в локальную базу.
    

## Руководство по установке

SPM
-------------

IQChannelsSwift доступен через [Swift Package Manager](https://www.swift.org/documentation/package-manager). Чтобы установить его, в Xcode выберите `File > Add Packages` и введите в поиск URL-адрес репозитория https://github.com/iqstore/iqchannels-swift

CocoaPods
-------------

IQChannelsSwift доступен через [CocoaPods](https://cocoapods.org). Чтобы установить его, добавьте следующую строку в ваш Podfile:

```ruby
pod 'IQChannelsSwift', :git => 'https://github.com/iqstore/iqchannels-swift.git', :tag => '2.3.8'
```

Затем выполните команду:

```bash
pod install
```

Разрешить в `info.plist` поддержку камеры и доступа к фоткам:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Описание использования галереи</string>
    <key>NSCameraUsageDescription</key>
    <string>Описание использования камеры</string>
</dict>
</plist>
```

## Примеры использования SDK


Инициализация c несколькими каналами
-------------

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let configurationManager: IQLibraryConfigurationProtocol = IQLibraryConfiguration()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = IQChannelsConfig(address: "https://example.com", channels: ["channel1", "channel2"])
        configurationManager.configure(config)
        
        return true
    }
}
```

Инициализация c одним каналом
-------------

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let configurationManager: IQLibraryConfigurationProtocol = IQLibraryConfiguration()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = IQChannelsConfig(address: "https://example.com", channels: ["channel1"])
        configurationManager.configure(config)
        
        return true
    }
}
```

Инициализация c определенным чатом
-------------

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let configurationManager: IQLibraryConfigurationProtocol = IQLibraryConfiguration()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = IQChannelsConfig(address: "https://example.com",
                                      channels: ["channel1", "channel2"],
                                      chatToOpen: ("channel1", IQChatType.manager)) // Чат который требуется открыть
        configurationManager.configure(config)
        
        return true
    }
}
```

Логин
-----
Логин/логаут пользователя осуществляется по внешнему токену/сессии, специфичному для конкретного приложения.
Для логина требуется вызвать в любом месте приложения:

```swift
configurationManager.login(.credentials("myLoginToken"))
```

Для логаута:
```swift
configurationManager.logout()
```

После логина внутри SDK создается сессия пользователя и начинается бесконечный цикл, который подключается
к серверу и начинает слушать события о новых сообщения, при обрыве соединения или любой другой ошибке
сессия переподключается к серверу. При отсутствии сети, сессия ждет, когда последняя станет доступна.


Анонимные пользователи
----------------------
Чат может использоваться в анонимном режиме. Для этого после конфигурации нужно вызвать: 

```swift
configurationManager.login(.anonymous)
```

Для логаута:
```swift
configurationManager.logout()
```

Анонимный логин автоматически зарегистрирует нового анонимного пользователя, если нужно,
а потом его авторизует.

Отображение чата
--------------

Метод getViewController предназначен для получения основного навигационного контроллера (UINavigationController) библиотеки IQChannelsSwift. Этот контроллер используется как корневой контроллер для отображения пользовательского интерфейса библиотеки.

```swift
func showMessages() {
    if let navigationController = configuration.getViewController() {
        present(navigationController, animated: true)
    }
}
```

Метод getChatViewController предназначен для получения контроллера окна с чатом (UIViewController) библиотеки IQChannelsSwift. Этот контроллер используется только для показа определенного чата и может быть получен только после успешной авторизации.

```swift
configuration.login(.anonymous) {
    DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        let сhatViewController = self.configuration.getChatViewController()
    }
}
```

Отображение непрочитанных сообщений
-----------------------------------
Для отображения непрочитанных сообщений нужно добавить слушателя, в который будет присылаться количество
непрочитанных сообщений `в текущем чате`. Слушателя нужно добавлять после конфигурации и логина.

Пример реализации:
```swift
class ViewController: UIViewController, UITextFieldDelegate, IQChannelsUnreadListenerProtocol {
    var id: String {
        UUID().uuidString
    }
    
    let configuration: IQLibraryConfigurationProtocol = IQLibraryConfiguration()
    
    func iqChannelsUnreadDidChange(_ unread: Int) {
        self.unreadLabel.text = "Непрочитанных сообщений: \(unread)"
    }
    
    private lazy var unreadLabel: UILabel = {
        let label = UILabel()
        label.text = "Непрочитанных сообщений: nil"
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setServer(server: "https://example.ru")   // Конфигурация
        configuration.login(.anonymous)           // Логин
        configuration.addUnread(listener: self)   // Добавление слушателя
    }
}
```

Отображение расширенных непрочитанных сообщений
-----------------------------------
Для отображения расширенных непрочитанных сообщений нужно добавить слушателя, в который будет присылаться json с данными о непрочитанных сообщениях. Слушателя нужно добавлять после конфигурации и логина.

Пример реализации:
```swift
class ViewController: UIViewController, UITextFieldDelegate, IQChannelsAdvancedUnreadListenerProtocol {
    var id: String {
        UUID().uuidString
    }
    
    let configuration: IQLibraryConfigurationProtocol = IQLibraryConfiguration()
    
    func iqChannelsAdvancedUnreadDidChange(_ unread: IQChannelsSwift.IQAdvancedUnread) {
        DispatchQueue.main.async {
            self.advancedUnreadLabel.text = "\(unread)"
        }
    }
    
    func iqChannelsAdvancedUnreadException(_ e: any Error) {
        DispatchQueue.main.async {
            self.advancedUnreadLabel.text = "\(e)"
        }
    }
    
    private lazy var advancedUnreadLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setServer(server: "https://example.ru")   // Конфигурация
        configuration.login(.anonymous)           // Логин
        configuration.addAdvancedUnread(listener: self)   // Добавление слушателя
    }
}
```

Отображение логов сдк
-----------------------------------
Для отображения логов из сдк нужно добавить флаг в конфиг.

Пример реализации:
```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let configurationManager: IQLibraryConfigurationProtocol = IQLibraryConfiguration()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = IQChannelsConfig(address: "https://example.com",
                                      channels: ["channel1", "channel2"],
                                      logging: true) // Включение логирования
        configurationManager.configure(config)
        
        return true
    }
}
```

Отправка пуш-токенов
--------------------
Для поддержки пуш-уведомлений требуется при старте приложения запросить у пользователя возможность
отправлять ему уведомления, а потом передать токен в библиотеку. Токен можно передавать в любой момент, 
в т.ч. до конфигурации и логина.

Пример реализации `UIApplicationDelegate`:
```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let configuration: IQLibraryConfigurationProtocol = IQLibraryConfiguration()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForNotifications(application)
        return true
    }

    func registerForNotifications(_ application: UIApplication) {
        let settings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
        application.registerUserNotificationSettings(settings)
    }

    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        guard notificationSettings.types != [] else {
            return
        }
        application.registerForRemoteNotifications()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        configuration.pushToken(deviceToken)
    }
}
```
## Пример использования перехватчика событий

Чтобы обработать событие при нажатии кнопки "Назад" и при необходимости отменить его, нужно реализовать методы протокола IQChannelsEventListenerProtocol.

``` swift
class AppDelegate: UIResponder, UIApplicationDelegate, IQChannelsEventListenerProtocol {
    
    let configurationManager: IQLibraryConfigurationProtocol = IQLibraryConfiguration()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = IQChannelsConfig(address: "https://example.com", channels: ["channel1"])
        configurationManager.configure(config)
        configuration.addEvent(listener: self)

        return true
    }

    func iqChannelsShouldCloseModule() -> Bool {
        // Вызывается при попытке закрыть модуль, вернуть `false`, чтобы предотвратить закрытие
        return true
    }

    func iqChannelsShouldCloseChat() -> Bool {
        // Вызывается при попытке закрыть чат, вернуть `false`, чтобы предотвратить закрытие
        return true
    }
}
```

## Пример использования стилизации

Для переключения темы следует использовать метод IQChannelsConfig.setTheme

Пример переключения темы
  
```swift
let config = IQChannelsConfig(address: "https://example.com", channels: ["channel1"], styleJson: json)
config.setTheme(.dark)
configurationManager.configure(config)
```

Поддерживаемые темы (IQTheme)
  
```swift
public enum IQTheme {
    /** Принудительно темная */ case dark
    /** Принудительно светлая */ case light
    /** Автоматически меняется вместе с темой устройства */ case system
}
```

Для того чтобы поменять стили элементов внутри SDK, нужно передать поддерживаемый JSON файл. Его можно передать как при инициализации, так и после нее, channelManager при этом не переопределяется

<details>
  <summary>Пример подгрузки темы из Json</summary>
  
```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let configurationManager: IQLibraryConfigurationProtocol = IQLibraryConfiguration()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let json: Data = // JSON файл в формате Data 
        let config = IQChannelsConfig(address: "https://example.com", channels: ["channel1"], styleJson: json)
        configurationManager.configure(config)
        
        return true
    }
}
```
</details>

--------------------

<details>
  <summary>Пример JSON для передачи в SDK</summary>

```json
{
  "signup": {                 //Авторизация: (только Android)
    "background": {           //Фон
      "light": "#FFFFFF",     //Цвет для светлой темы
      "dark": "#FFFFE0"       //Цвет для темной темы
    },
    "title": {                //Заголовок
      "color": {              //Цвета для светлой и темной темы
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,        //Размер текста
      "text_align": "center", //Выравнивание текста
      "text_style": {
        "bold": true,         //Жирность
        "italic": false       //Курсив
      }
    },
    "subtitle": {             //Подзаголовок
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "input_background": {     //Фон области ввода имени
      "color": {
        "light": "#FFFFFF",
        "dark": "#000000"
      },
      "border": {             //Обводка
        "size": 0,            //Толщина
        "color": {            //Цвета для светлой и темной темы
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0    //Скругление
      }
    },
    "input_text": {           //Текст в поле ввода
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "check_box_disabled": {       //Цвет неактивного чекбокса
      "light": "#сссссс",
      "dark": "#сссссс"
    },
    "check_box_enabled": {       //Цвет активного чекбокса
      "light": "#0d35ff",
      "dark": "#0d35ff"
    },
    "check_box_text": {       //Текст возле чекбокса
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "left",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "button": {               //Кнопка входа
      "background_enabled": { //Активная кнопка
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border": {
          "size": 0,
          "color": {
            "light": "#000000",
            "dark": "#000000"
          },
          "border-radius": 0
        }
      },
      "background_disabled": { //Неактивная кнопка
        "color": {
          "light": "#555555",
          "dark": "#555555"
        },
        "border": {
          "size": 0,
          "color": {
            "light": "#000000",
            "dark": "#000000"
          },
          "border-radius": 0
        }
      },
      "text_enabled": {       //Текст на активной кнопке
        "color": {
          "light": "#FFFFFF",
          "dark": "#FFFFFF"
        },
        "text_size": 10,
        "text_align": "center",
        "text_style": {
          "bold": false,
          "italic": false
        }
      },
      "text_disabled": {      //Текст на неактивной кнопке
        "color": {
          "light": "#FFFFFF",
          "dark": "#FFFFFF"
        },
        "text_size": 10,
        "text_align": "center",
        "text_style": {
          "bold": false,
          "italic": false
        }
      }
    },
    "error_text": {           //Текст ошибки
      "color": {
        "light": "#c70037",
        "dark": "#c70037"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    }
  },
  "app_bar": {                 //Верхняя панель
    "background": {           //Фон панели
      "light": "#FFFFFF",
      "dark": "#FFFFE0"
    },
    "back_button": {          // Цвет иконки "Назад"
      "light": "#000000",
      "dark": "#ffffff"
    },
    "status_label": {         //Текст статуса 
      "color": {
        "light": "#888888",
        "dark": "#888888"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "title_label": {          //Заголовок в шапке чата
      "color": {
        "light": "#888888",
        "dark": "#888888"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    }
  },
  "chat": {                   //Общий чат:
    "background": {           //Фон чата
      "light": "#FFFFFF",
      "dark": "#FFFFE0"
    },
    "date_text": {            //Текст относительной даты чата (по середине)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "chat_history": {         //Верхний индикатор загрузки предыдущих сообщений
      "light": "#008080",
      "dark": "#008080"
    },
    "chat_loader": {          //индикатор загрузки сообщений (основной лоадер)
      "light": "#008080",
      "dark": "#008080"
    },
    "icon_operator": "https://gas-kvas.com/grafic/uploads/posts/2024-01/gas-kvas-com-p-logotip-cheloveka-na-prozrachnom-fone-4.png", //Иконка оператора
    "system_text": {          //Системные сообщения
      "color": {
        "light": "#888888",
        "dark": "#888888"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "new_message_background": {    //Фон панели "Новые сообщения"
        "light": "#F4F4F8",
        "dark": "#F4F4F8"
    },
    "scroll_down_button_background": { //Фон кнопки скролла вниз
      "color": {
        "light": "#FFFFE0",
        "dark": "#808080"
      },
      "border": {
        "size": 1,
        "color": {
          "light": "#E4E8ED",
          "dark": "#E4E8ED"
        }
      }
    },
    "scroll_down_button_icon_color": { //Цвет иконки у кнопки скролла вниз
      "light": "#cccccc",
      "dark": "#cccccc"
    }
  },
  "messages": {               //Сообщение отправка текста (стили применяются ко всем производным сообщениям):
    "background_operator": {  //Фон контейнера (оператор)
      "color": {
        "light": "#FFFFE0",
        "dark": "#808080"
      },
      "border": {
        "size": 0,
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0
      }
    },
    "background_client": {    //Фон контейнера (клиент)
      "color": {
        "light": "#242729",
        "dark": "#808080"
      },
      "border": {
        "size": 0,
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0
      }
    },
    "text_operator": {        //Текст сообщения (оператор)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_client": {          //Текст сообщения (клиент)
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "reply_text_client": {    //Текст сообщения, на которое ответил клиент
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "reply_sender_text_client": {   //Имя отправителя сообщения, на которое ответил клиент
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "reply_left_line_client": {     //Линия слева от ответного сообщения (Клиент)
      "light": "#FF0000",
      "dark": "#FF0000"
    },
    "reply_text_operator": {        //Основной текст ответа со стороны оператора
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "reply_sender_text_operator": { //Имя отправителя сообщения, на которое ответил оператор
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "reply_left_line_operator": {   //Линия слева от ответного сообщения (Оператор)
      "light": "#FF0000",
      "dark": "#FF0000"
    },
    "text_time_operator": {         //Текст времени доставки (Оператор)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_time_client": {           //Текст времени доставки (Клиент)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_up": {                    //Текст над контейнером (Имя оператора/бота)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_state_rejected_operator": { //Текст файла от оператора при статусе rejected
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_state_on_checking_operator": { //Текст файла от оператора при статусе on_checking
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_state_sent_for_checking_operator": { //Текст файла от оператора при статусе sent_for_checking
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_state_check_error_operator": { //Текст файла от оператора при статусе check_error
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_state_rejected_client": { //Текст файла от клиента при статусе rejected
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_state_on_checking_client": { //Текст файла от клиента при статусе on_checking
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_state_sent_for_checking_client": { //Текст файла от клиента при статусе sent_for_checking
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_state_check_error_client": { //Текст файла от клиента при статусе check_error
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "checkmark_read": {                   //Цвет прочитаннной галочки
      "light": "#cccccc",
      "dark": "#cccccc"
    },
    "checkmark_received": {                //Цвет доставленной галочки
      "light": "#cccccc",
      "dark": "#cccccc"
    },
    "sending": {                          //Цвет кружочка загрузки
      "light": "#cccccc",
      "dark": "#cccccc"
    },
    "error_icon": {                       //Восклицательный знак у ошибки сообщения
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "error_background": {                 //Фон иконки у ошибки сообщения
      "light": "#FF0000",
      "dark": "#FF0000"
    },
    "error_popup_menu_background": {       //Фон попап меню у ошибки сообщения
      "color": {
        "light": "#ffffff",
        "dark": "#ffffff"
      },
      "border": {
        "size": 1,
        "color": {
          "light": "#cccccc",
          "dark": "#cccccc"
        },
        "border-radius": 10
      }
    },
    "error_popup_menu_text": {             //Текст кнопок в попап меню у ошибки сообщения
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    }
  },
  "answer": {                 //Ответ на сообщения:
    "text_sender": {          //Текст сообщения над полем ввода
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_message": {         //Текст сообщения в отвеченном сообщении
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "background_text_up_message": {       //Фон текста сообщения над полем ввода
      "light": "#FFFACD",
      "dark": "#808080"
    },
    "icon_cancel": "https://w7.pngwing.com/pngs/21/486/png-transparent-undo-common-toolbar-icon.png",     //Кнопка закрыть/отменить – вид кнопки(изменяется с помощью файла с иконкой)
    "left_line": {                        //Прямая вертикальная линия рядом с сообщением, на которое отвечаем - цвет
      "light": "#FF0000",
      "dark": "#FF0000"
    },
    "text_operator_typing": {             //Текст "Оператор печатает..." (Только Android)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "background_operator_typing": {       //Фон плашки "Оператор печатает..." (Только Android)
      "light": "#FFFACD",
      "dark": "#808080"
    }
  },
  "messages_file": {                      //Сообщение отправка файла:
    "text_filename_client": {             //Цвет названия файла со стороны клиента
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_filename_operator": {           //Цвет названия файла со стороны оператора
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "icon_file_client": "https://1000logos.net/wp-content/uploads/2023/01/Google-Docs-logo.png",      //Иконка файла со стороны клиента
    "icon_file_operator": "https://1000logos.net/wp-content/uploads/2023/01/Google-Docs-logo.png",    //Иконка файла со стороны оператора
    "text_file_size_client": {             //Цвет размера файла со стороны клиента
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_file_size_operator": {            //Цвет размера названия файла со стороны оператора
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    }
  },
  "change_segment": {                       //Сообщение с кнопкой для перехода в другой сегмент
    "background_container": {               //Фон сообщения
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "border": {
        "size": 10,
        "color": {
          "light": "#ffffff",
          "dark": "#FFFFFF"
        },
        "border-radius": 50
      }
    },
    "title": {                              //Заголовок сообщения
      "color": {
        "light": "#000000",
        "dark": "#000000"
      },
      "text_size": 22,
      "text_align": "center",
      "text_style": {
        "bold": true,
        "italic": true
      }
    },
    "background_button": {                  //Фон кнопки
      "color": {
        "light": "#008080",
        "dark": "#008080"
      },
      "border": {
        "size": 5,
        "color": {
          "light": "#008080",
          "dark": "#008080"
        },
        "border-radius": 15
      }
    },
    "text_button": {                       //Текст кнопки
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "text_size": 20,
      "text_align": "center",
      "text_style": {
        "bold": true,
        "italic": true
      }
    }
  },
  "rating": {                             //Сообщение оценки качества:
    "background_container": {             //Фон контейнера - по умолчанию как у сообщения
      "color": {
        "light": "#FFFACD",
        "dark": "#808080"
      },
      "border": {
        "size": 0,
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0
      }
    },
    "rating_title": {                     //Заголовок вопроса
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "full_star": "https://img2.freepng.ru/20180621/itr/kisspng-business-5-star-probot-artistry-hotel-farah-5b2bdea0157717.8623271415296016960879.jpg",    //Закрашенная звезда – вид иконки(изменяется с помощью файла с иконкой)
    "empty_star": "https://www.downloadclipart.net/large/rating-star-background-png.png", //Незакрашенная звезда – вид иконки(изменяется с помощью файла с иконкой)
    "sent_rating": {                      //Кнопка отправки оценки
      "background_enabled": {             //Активная кнопка
        "color": {
          "light": "#008080",
          "dark": "#008080"
        },
        "border": {
          "size": 0,
          "color": {
            "light": "#000000",
            "dark": "#000000"
          },
          "border-radius": 0
        }
      },
      "background_disabled": {            //Неактивная кнопка
        "color": {
          "light": "#B7B7CA",
          "dark": "#B7B7CA"
        },
        "border": {
          "size": 0,
          "color": {
            "light": "#000000",
            "dark": "#000000"
          },
          "border-radius": 0
        }
      },
      "text_enabled": {                   //Текст на активной кнопке
        "color": {
          "light": "#ffffff",
          "dark": "#FFFFFF"
        },
        "text_size": 10,
        "text_align": "center",
        "text_style": {
          "bold": false,
          "italic": false
        }
      },
      "text_disabled": {                  //Текст на неактивной кнопке
        "color": {
          "light": "#ffffff",
          "dark": "#FFFFFF"
        },
        "text_size": 10,
        "text_align": "center",
        "text_style": {
          "bold": false,
          "italic": false
        }
      }
    },
    "answer_button": {                    //Кнопки выбора в вопросе
      "background_enabled": {             //Активная кнопка
        "color": {
          "light": "#008080",
          "dark": "#008080"
        },
        "border": {
          "size": 0,
          "color": {
            "light": "#000000",
            "dark": "#000000"
          },
          "border-radius": 0
        }
      },
      "background_disabled": {            //Неактивная кнопка
        "color": {
          "light": "#B7B7CA",
          "dark": "#B7B7CA"
        },
        "border": {
          "size": 0,
          "color": {
            "light": "#000000",
            "dark": "#000000"
          },
          "border-radius": 0
        }
      },
      "text_enabled": {                   //Текст на активной кнопке
        "color": {
          "light": "#ffffff",
          "dark": "#FFFFFF"
        },
        "text_size": 10,
        "text_align": "center",
        "text_style": {
          "bold": false,
          "italic": false
        }
      },
      "text_disabled": {                  //Текст на неактивной кнопке
        "color": {
          "light": "#ffffff",
          "dark": "#FFFFFF"
        },
        "text_size": 10,
        "text_align": "center",
        "text_style": {
          "bold": false,
          "italic": false
        }
      }
    },
    "scale_button": {                     //Кнопки в вопросе типа "Scale"
      "background_enabled": {             //Активная кнопка
        "color": {
          "light": "#008080",
          "dark": "#008080"
        },
        "border": {
          "size": 0,
          "color": {
            "light": "#000000",
            "dark": "#000000"
          },
          "border-radius": 0
        }
      },
      "background_disabled": {            //Неактивная кнопка
        "color": {
          "light": "#B7B7CA",
          "dark": "#B7B7CA"
        },
        "border": {
          "size": 0,
          "color": {
            "light": "#000000",
            "dark": "#000000"
          },
          "border-radius": 0
        }
      },
      "text_enabled": {                   //Текст на активной кнопке
        "color": {
          "light": "#ffffff",
          "dark": "#FFFFFF"
        },
        "text_size": 10,
        "text_align": "center",
        "text_style": {
          "bold": false,
          "italic": false
        }
      },
      "text_disabled": {                  //Текст на неактивной кнопке
        "color": {
          "light": "#ffffff",
          "dark": "#FFFFFF"
        },
        "text_size": 10,
        "text_align": "center",
        "text_style": {
          "bold": false,
          "italic": false
        }
      }
    },
    "scale_min_text": {                   //Текст низкой оценки (Scale)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "left",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "scale_max_text": {                   //Текст высокой оценки (Scale)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "right",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "input_background": {                 //Фон поля ввода в вопросе типа "Input"
      "color": {
        "light": "#ffffff",
        "dark": "#FFFFFF"
      },
      "border": {
        "size": 0,
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0
      }
    },
    "input_text": {                       //Текст поля ввода в вопросе типа "Input"
      "color": {
        "light": "#000000",
        "dark": "#000000"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "feedback_thanks_text": {             //Текст благодарности за прохождение опроса
      "color": {
        "light": "#000000",
        "dark": "#000000"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    }
  },
  "tools_to_message": {                   //Панель инструментов (для отправки сообщений):
    "background": {                       //Фон панели
      "light": "#ffffff",
      "dark": "#696969"
    },
    "icon_sent": "https://e7.pngegg.com/pngimages/414/329/png-clipart-computer-icons-share-icon-edit-angle-triangle.png", //Иконка-кнопка для отправки – вид кнопки(изменяется с помощью файла с иконкой)
    "background_icon_sent": {                  //Фон иконки для отправки
      "color": {
        "light": "#DEB887",
        "dark": "#696969"
      },
      "border": {
        "size": 0,
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0
      }
    },
    "background_input": {                  //Фон области ввода текста
      "color": {
        "light": "#DEB887",
        "dark": "#696969"
      },
      "border": {
        "size": 0,
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0
      }
    },
    "text_input": {                        //Текст в поле ввода
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "icon_clip": "https://cdn-icons-png.flaticon.com/512/84/84281.png",  //Иконка-кнопка 'скрепка' - вид кнопки(изменяется с помощью файла с иконкой)
    "background_icon_clip": {                  //Фон иконки для выбора вложений
      "color": {
        "light": "#DEB887",
        "dark": "#696969"
      },
      "border": {
        "size": 0,
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0
      }
    },
    "cursor_color": {                     //Цвет курсора (Только iOS)
      "light": "#525252",
      "dark": "#525252"
    }
  },
  "error": {                              //Страница ошибки:
    "title_error": {                      //Заголовок
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "text_error": {                       //Основной текст
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "icon_error": "https://w7.pngwing.com/pngs/285/84/png-transparent-computer-icons-error-super-8-film-angle-triangle-computer-icons.png",          //Иконка ошибки - вид иконки(изменяется с помощью файла с иконкой)
    "background_button_error": {                  //Фон кнопки
      "color": {
        "light": "#cccccc",
        "dark": "#cccccc"
      },
      "border": {
        "size": 0,
        "color": {
          "light": "#000000",
          "dark": "#000000"
        },
        "border-radius": 0
      }
    },
    "text_button_error": {                       //Текст кнопки
      "color": {
        "light": "#000000",
        "dark": "#000000"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    }
  },
  "single-choice": {                    //Single-choice сообщение:
    "background_button": {              //Фон кнопки Single-choice
      "light": "#FFFF00",
      "dark": "#00FFFF"
    },
    "border_button": {                  //Граница IVR кнопки Single-choice (isDropDown)
      "size": 3,
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "border-radius": 10
    },
    "text_button": {                    //Текст кнопки Single-choice
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    },
    "background_IVR": {                 //Фон IVR кнопки Single-choice (isDropDown)
      "light": "#00000000",
      "dark": "#00000000"
    },
    "border_IVR": {                     //Граница IVR кнопки Single-choice (isDropDown)
      "size": 1,
      "color": {
        "light": "#74b928",
        "dark": "#74b928"
      },
      "border-radius": 10
    },
    "text_IVR": {                       //Текст IVR кнопки Single-choice (isDropDown)
      "color": {
        "light": "#000000",
        "dark": "#FFFFFF"
      },
      "text_size": 10,
      "text_align": "center",
      "text_style": {
        "bold": false,
        "italic": false
      }
    }
  },
  "theme": "light"                      //Выбранная тема (светлая/темная)
}
```
</details>




## Пример использования мультиязычности

Для подключения перевода необходимо добавить поддерживаемые JSON файлы с локализацией (в том числе и русской). Имя файлов обязательно должно быть `ru.json`, `en.json` и т.д.

Пример добавления файла с локализацией
  
```swift
extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        guard let url = urls.first,
              url.startAccessingSecurityScopedResource() else { return }
        
        selectedLanguage = try? Data(contentsOf: url)
        saveLanguageFile(url)
        
        url.stopAccessingSecurityScopedResource()
    }
    
    func saveLanguageFile(_ url: URL) {
        do {
            let fileName = url.lastPathComponent
            let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
            let destinationURL = appSupportDir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
        } catch {
            print("Ошибка при копировании файла: \(error)")
        }
    }
}
```

--------------------

<details>
  <summary>Пример JSON файла с локализацией для передачи в SDK</summary>

```json
{
 "code": "ru",
 "signup_title": "Представьтесь, пожалуйста,",
 "signup_subtitle": "желательно указать фамилию и имя:",
 "signup_name_placeholder": "Ваше имя",
 "signup_checkbox_text": "Согласие на обработку персональных данных",
 "signup_button_text": "Начать чат",
 "signup_error": "Ошибка: длина имени должна быть не менее 3-х символов.",
 "title_error": "Чат временно недоступен",
 "text_error": "Мы уже все исправляем. Обновите страницу или попробуйте позже",
 "title_error_pm": "Нет закреплённого персонального менеджера",
 "text_error_pm": "Обратитесь в чат с тех. поддержкой",
 "button_error": "Вернуться",
 "status_label": "На связи",
 "status_label_awaiting_network": "Ожидание сети...",
 "operator_typing": "печатает",
 "input_message_placeholder": "Сообщение",
 "text_file_state_rejected": "Небезопасный файл",
 "text_file_state_on_checking": "Файл на проверке",
 "text_file_state_sent_for_check": "Файл отправлен на проверку",
 "text_file_state_check_error": "Ошибка проверки файла",
 "rating_state_pending": "Пожалуйста, оцените качество консультации",
 "rating_state_ignored": "Без оценки оператора",
 "rating_state_rated": "Оценка оператора {{client_rating}} из {{max_rating}}",
 "new_messages": "Новые сообщения",
 "sent_rating": "Отправить",
 "invalid_messsage": "Неподдерживаемый тип сообщения",
 "image_load_error": "Ошибка загрузки",
 "rating_offer_title": "Желаете пройти опрос?",
 "rating_offer_yes": "Да",
 "rating_offer_no": "Нет",
 "sender_name_anonym": "Аноним",
 "sender_name_system": "Система",
 "text_copied": "Сообщение скопировано",
 "copy": "Копировать",
 "reply": "Ответить",
 "resend": "Повторить отправку",
 "delete": "Удалить",
 "file_saved_title": "Успешно!",
 "file_saved_text": "Файл успешно сохранен.",
 "file_saved_error": "Не удалось загрузить файл",
 "photo_saved_success_title": "Успешно!",
 "photo_saved_error_title": "Ошибка!",
 "photo_saved_success_text": "Фото успешно сохранено в галерею.",
 "photo_saved_error_text": "Не удалось сохранить фото.",
 "gallery_permission_denied_title": "Доступ к галерее запрещён",
 "gallery_permission_denied_text": "Пожалуйста, разрешите доступ в настройках, чтобы сохранять фото.",
 "gallery_permission_alert_cancel": "Отмена",
 "gallery_permission_alert_settings": "В настройки",
 "file_size_error": "Слишком большая ширина или высота изображения",
 "file_weight_error": "Превышен максимально допустимый размер файла",
 "file_not_allowed": "Неподдерживаемый тип файла",
 "file_forbidden": "Запрещенный тип файла",
 "gallery": "Галерея",
 "file": "Файл",
 "camera": "Камера",
 "cancel": "Отмена",
 "today": "Сегодня"
 }
```
</details>
