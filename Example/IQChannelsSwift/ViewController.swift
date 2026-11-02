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

class ViewController: UIViewController, UITextFieldDelegate, IQChannelsUnreadListenerProtocol, IQChannelsAdvancedUnreadListenerProtocol, IQChannelsLinkListenerProtocol {
    
    var isPickingStyle = false
    
    var id: String {
        UUID().uuidString
    }
    func iqChannelsUnreadDidChange(_ unread: Int) {
        DispatchQueue.main.async {
            self.unreadLabel.text = "Непрочитанных сообщений: \(unread)"
        }
    }
    
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
    
    private lazy var authLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "Авторизация успешна: nil"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var unreadLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "Непрочитанных сообщений: nil"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var advancedUnreadLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "Тут будут расширенные непрочитанные сообщения"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
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
            serverField, emailField, channelsField, chatToOpenField, authLabel, unreadLabel, advancedUnreadLabel, loginButton, anonButton, pmButton, preFilledMsgButton, styleButton, languageButton, changeStyle, buttons, clearCacheButton, typingBarRow
        ])
        view.spacing = 5
        view.axis = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var configuration: IQLibraryConfigurationProtocol!
    
    var selectedStyle: Data?
    var preFillMessages: IQPreFillMessages?
    
    var serverString = ""
    var channelsArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDismissKeyboardOnTap()
        view.addSubview(scrollView)
        view.backgroundColor = .white
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
                stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
                stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),

                stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

                loginButton.heightAnchor.constraint(equalToConstant: 48)
            ])
        
        
        emailField.delegate = self
        serverField.delegate = self
        channelsField.delegate = self
        chatToOpenField.delegate = self
        
        let cached = UserDefaults.standard
        let savedServer = cached.string(forKey: "cached_server_field")
        let savedEmail = cached.string(forKey: "cached_email_field")
        let savedChannels = cached.string(forKey: "cached_channels_field")
        let savedChatToOpen = cached.string(forKey: "cached_chat_to_open_field")
        
        setServer(server: savedServer ?? "https://iqchannels.isimplelab.com")
        
        if let savedEmail {
            emailField.text = savedEmail
        }
        if let savedChatToOpen {
            chatToOpenField.text = savedChatToOpen
        }
        channelsField.text = savedChannels ?? channelsField.text

        configuration.login(.anonymous) { success in
            DispatchQueue.main.async {
                self.authLabel.text = "Авторизация успешна: \(success)"
            }
        }
        
        configuration.addUnread(listener: self)
        configuration.addLink(listener: self)
        
        navigationControl = configuration.getViewController()
    }

    func setServer(server: String?, chatToOpen: IQChannelsConfig.ChatToOpen? = nil) {
        let urlSession: URLSession? = nil
        serverString = (server?.isEmpty ?? true) ? "" : (server ?? "")
        channelsArray = channelsField.text?.components(separatedBy: .whitespaces) ?? []
        let config = IQChannelsConfig(address: serverString,
                                      channels: channelsArray,
                                      chatToOpen: chatToOpen,
                                      styleJson: selectedStyle,
                                      logging: true,
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
        
        configuration.login(.credentials(textField.text ?? "")) { success in
            DispatchQueue.main.async {
                self.authLabel.text = "Авторизация успешна: \(success)"
            }
        }
        showMessages()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveFieldsToCache()
    }
    
    private func saveFieldsToCache() {
        let cached = UserDefaults.standard
        cached.set(serverField.text ?? "", forKey: "cached_server_field")
        cached.set(emailField.text ?? "", forKey: "cached_email_field")
        cached.set(channelsField.text ?? "", forKey: "cached_channels_field")
        cached.set(chatToOpenField.text ?? "", forKey: "cached_chat_to_open_field")
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
    
    @objc private func typingBarSwitchChanged(_ sender: UISwitch) {
        showBottomTypingBar = sender.isOn
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
        saveFieldsToCache()
        if let channel = chatToOpenField.text, !channel.isEmpty {
            setServer(server: serverField.text, chatToOpen: (channel: channel, chatType: IQChatType.chat))
        } else {
            setServer(server: serverField.text)
        }
        
        configuration.login(.credentials(emailField.text ?? "")) { success in
            DispatchQueue.main.async {
                self.authLabel.text = "Авторизация успешна: \(success)"
            }
        }
        configuration.addAdvancedUnread(listener: self)
        showMessages()
    }
    
    @objc func anonymousDidTap() {
        saveFieldsToCache()
        if let channel = chatToOpenField.text, !channel.isEmpty {
            setServer(server: serverField.text, chatToOpen: (channel: channel, chatType: IQChatType.chat))
        } else {
            setServer(server: serverField.text)
        }
        
        configuration.login(.anonymous) { success in
            DispatchQueue.main.async {
                self.authLabel.text = "Авторизация успешна: \(success)"
            }
        }
        configuration.addAdvancedUnread(listener: self)
        showMessages()
    }
    
    @objc func pmDidTap() {
        if let channel = chatToOpenField.text, !channel.isEmpty {
            setServer(server: serverField.text, chatToOpen: (channel: channel, chatType: IQChatType.manager))
        } else {
            let channel = channelsField.text?.components(separatedBy: .whitespaces).first ?? "support"
            setServer(server: serverField.text, chatToOpen: (channel: channel, chatType: IQChatType.manager))
        }
        configuration.login(.credentials(emailField.text ?? "")) { success in
            DispatchQueue.main.async {
                self.authLabel.text = "Авторизация успешна: \(success)"
            }
        }
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
