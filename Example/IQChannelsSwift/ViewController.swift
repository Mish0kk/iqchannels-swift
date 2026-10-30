//
//  ViewController.swift
//  IQChannelsSwift
//
//  Created by Daulet Tokmukhanbet on 05/05/2024.
//  Copyright (c) 2024 Daulet Tokmukhanbet. All rights reserved.
//

import UIKit
import IQChannelsSwift
import SDWebImage

var navigationControl: UINavigationController?

class ViewController: UIViewController, UITextFieldDelegate, IQChannelsUnreadListenerProtocol, IQChannelsLinkListenerProtocol {
    var isPickingStyle = false
    
    var id: String {
        UUID().uuidString
    }
    func iqChannelsUnreadDidChange(_ unread: Int) {
        DispatchQueue.main.async {
            self.unreadLabel.text = "Непрочитанных сообщений: \(unread)"
        }
    }
    
    func iqChannelsShouldHandleLink(link: String) -> Bool {
        print("LINK TAPPED: \(link)")
        return true
    }
    
    
    
    private lazy var serverField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "server"
        field.addToolbar()
        return field
    }()
    
    private lazy var emailField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.text = "101"
        field.addToolbar()
        return field
    }()
    
    private lazy var channelsField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.text = "support"
        field.addToolbar()
        return field
    }()
    
    private lazy var chatToOpenField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.attributedPlaceholder = NSAttributedString(
            string: "Чат для открытия",
        )
        field.autocapitalizationType = .none
        field.addToolbar()
        return field
    }()
    
    private lazy var unreadLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "Непрочитанных сообщений: nil"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var styleButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Загрузить стили", for: .normal)
        button.addTarget(self, action: #selector(styleDidTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var changeStyle: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "Выбор темы для стилей:"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var styleDark: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Тёмный", for: .normal)
        button.addTarget(self, action: #selector(styleDarkTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var styleLight: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Светлый", for: .normal)
        button.addTarget(self, action: #selector(styleLightTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var styleSystem: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Системный", for: .normal)
        button.addTarget(self, action: #selector(styleSystemTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Войти", for: .normal)
        button.addTarget(self, action: #selector(loginDidTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var anonButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Анонимный чат", for: .normal)
        button.addTarget(self, action: #selector(anonymousDidTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var pmButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Чат с ПМ", for: .normal)
        button.addTarget(self, action: #selector(pmDidTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var preFilledMsgButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Предзаполненные сообщения", for: .normal)
        button.addTarget(self, action: #selector(preFilledMsgDidTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var languageButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Загрузить файл локализации", for: .normal)
        button.addTarget(self, action: #selector(languageDidTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var clearCacheButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Очистить кэш", for: .normal)
        button.addTarget(self, action: #selector(clearCacheDidTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var showBottomTypingBar = true
    
    private lazy var typingBarSwitch: UISwitch = {
        let sw = UISwitch()
        sw.isOn = showBottomTypingBar
        sw.addTarget(self, action: #selector(typingBarSwitchChanged), for: .valueChanged)
        return sw
    }()
    
    private lazy var typingBarRow: UIStackView = {
        let label = UILabel()
        label.text = "Надпись \"Оператор печатает...\" внизу"
        label.textColor = .black
        let row = UIStackView(arrangedSubviews: [label, typingBarSwitch])
        row.axis = .horizontal
        row.spacing = 8
        return row
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var stackView: UIStackView = {
        let buttons = UIStackView(arrangedSubviews: [
            styleDark, styleLight, styleSystem
        ])
        
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 5
        
        let view = UIStackView(arrangedSubviews: [
            serverField, emailField, channelsField, chatToOpenField, unreadLabel, advancedUnreadLabel, loginButton, anonButton, pmButton, preFilledMsgButton, styleButton, languageButton, changeStyle, buttons, clearCacheButton, typingBarRow
        ])
        view.spacing = 5
        view.distribution = .fillEqually
        view.axis = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var configuration: IQLibraryConfigurationProtocol = IQLibraryConfiguration()
    
    var selectedStyle: Data?
    var preFillMessages: IQPreFillMessages?
    
    var serverString = ""
    var channelsArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDismissKeyboardOnTap()
        view.addSubview(stackView)
        view.backgroundColor = .white
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        emailField.delegate = self
        
        setServer(server: "https://iqchannels.isimplelab.com")
        
        configuration.login(.anonymous)
        configuration.addUnread(listener: self)
        configuration.addLink(listener: self)
        
        navigationControl = configuration.getViewController()
    }

    func setServer(server: String?, chatToOpen: IQChannelsConfig.ChatToOpen? = nil) {
        // Сессия, сконфигурированная приложением: если передана — SDK использует её для запросов
        // и не выполняет собственную проверку сертификатов (serverTrust проверяет делегат сессии)
        let urlSession: URLSession? = nil
        serverString = (server?.isEmpty ?? true) ? "" : (server ?? "")
        channelsArray = channelsField.text?.components(separatedBy: .whitespaces) ?? []
        let config = IQChannelsConfig(address: serverString,
                                      channels: channelsArray,
                                      chatToOpen: chatToOpen,
                                      styleJson: selectedStyle,
                                      preFillMessages: preFillMessages,
                                      showBottomTypingBar: showBottomTypingBar,
                                      useRussianTrustedRootCA: false,
                                      urlSession: urlSession)
        preFillMessages = nil
        let headers = ["User-Agent": "MyAgent"]
        configuration.configure(config)
        configuration.setCustomHeaders(headers)
        serverField.text = server
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField === emailField else { return true }
        
        configuration.login(.credentials(textField.text ?? ""))
        showMessages()
        return true
    }
    
    func showMessages(){
        if let navigationController = configuration.getViewController() {
            present(navigationController, animated: true)
        }
    }
    
    @objc func languageDidTap(){
        isPickingStyle = false
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.allowsMultipleSelection = false
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc func clearCacheDidTap() {
        configuration.logout()
        
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        
        let fileManager = FileManager.default
        let directories: [FileManager.SearchPathDirectory] = [.applicationSupportDirectory, .cachesDirectory]
        for directory in directories {
            guard let url = fileManager.urls(for: directory, in: .userDomainMask).first else { continue }
            try? fileManager.removeItem(at: url)
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        
        if let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
           let files = try? fileManager.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil) {
            for file in files where !file.lastPathComponent.hasPrefix("iq_database") {
                try? fileManager.removeItem(at: file)
            }
        }
        
        let tmpPath = NSTemporaryDirectory()
        try? fileManager.removeItem(atPath: tmpPath)
        try? fileManager.createDirectory(atPath: tmpPath, withIntermediateDirectories: true)
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk(onCompletion: nil)
        
        UserDefaults.standard.set(true, forKey: "needs_db_wipe")
        
        DispatchQueue.main.async{
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                let viewController = ViewController()
                viewController.configuration = AppDelegate.configuration
                window.rootViewController = UINavigationController(rootViewController: viewController)
                viewController.showAlert(title: "", message: "Данные очищены")
            }
        }
    }
    
    @objc func styleDidTap(){
        isPickingStyle = true
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.allowsMultipleSelection = false
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc func styleDarkTap() {
        if selectedStyle == nil {
            showAlert(title: "Ошибка", message: "Сначала установите стили через кнопку \"Загрузить стили\"")
            return
        }
        configuration.setTheme(.dark)
        showAlert(title: "", message: "Установлена темная тема")
    }
    
    @objc func styleLightTap() {
        if selectedStyle == nil {
            showAlert(title: "Ошибка", message: "Сначала установите стили через кнопку \"Загрузить стили\"")
            return
        }
        configuration.setTheme(.light)
        showAlert(title: "", message: "Установлена светлая тема")
    }
    
    @objc func styleSystemTap() {
        if selectedStyle == nil {
            showAlert(title: "Ошибка", message: "Сначала установите стили через кнопку \"Загрузить стили\"")
            return
        }
        configuration.setTheme(.system)
        showAlert(title: "", message: "Установлена системная тема")
    }
    
    @objc func loginDidTap() {
        if let channel = chatToOpenField.text, !channel.isEmpty {
            setServer(server: serverField.text, chatToOpen: (channel: channel, chatType: IQChatType.chat))
        } else {
            setServer(server: serverField.text)
        }
        
        configuration.login(.credentials(emailField.text ?? ""))
        configuration.addUnread(listener: self)
        showMessages()
    }
    
    @objc func anonymousDidTap() {
        if let channel = chatToOpenField.text, !channel.isEmpty {
            setServer(server: serverField.text, chatToOpen: (channel: channel, chatType: IQChatType.chat))
        } else {
            setServer(server: serverField.text)
        }
        
        configuration.login(.anonymous)
        showMessages()
    }
    
    @objc func pmDidTap() {
        if let channel = chatToOpenField.text, !channel.isEmpty {
            setServer(server: serverField.text, chatToOpen: (channel: channel, chatType: IQChatType.manager))
        } else {
            var channel = channelsField.text?.components(separatedBy: .whitespaces).first ?? "support"
            setServer(server: serverField.text, chatToOpen: (channel: channel, chatType: IQChatType.manager))
        }
        configuration.login(.credentials(emailField.text ?? ""))
        showMessages()
    }
    
    @objc func preFilledMsgDidTap() {
        let preFillMsgView = PreFillMsgView()
        preFillMsgView.configuration = configuration
        
        preFillMsgView.setServer = { [weak self] preFillMessages in
            self?.preFillMessages = preFillMessages
            self?.setServer(server: self?.serverField.text)
        }
        
        navigationController?.pushViewController(preFillMsgView, animated: true)
    }
    
    private func setDismissKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func showAlert(title: String, message: String) {
        let alert: UIAlertController = .init(title: title,
                                             message: message,
                                             preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
            
            print("Файл успешно скопирован в: \(destinationURL.path)")
        } catch {
            print("Ошибка при копировании файла: \(error)")
        }
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        guard let url = urls.first,
              url.startAccessingSecurityScopedResource() else { return }
        
        if isPickingStyle {
            selectedStyle = try? Data(contentsOf: url)
        } else {
            saveLanguageFile(url)
        }
        
        url.stopAccessingSecurityScopedResource()
    }
}


extension UITextField {
    func addToolbar(withDismissText text: String = "Готово"){
        let toolbar = UIToolbar()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: text, style: .done,
                                         target: self, action: #selector(endEditing))
        toolbar.setItems([flexSpace, doneButton], animated: false)
        toolbar.sizeToFit()
        inputAccessoryView = toolbar
    }
}
