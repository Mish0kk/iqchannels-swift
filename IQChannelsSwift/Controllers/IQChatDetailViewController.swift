import UIKit
import Combine
import SwiftUI
import PhotosUI
import SafariServices
import Photos

class IQChatDetailViewController: IQViewController {
    
    // MARK: - PROPERTIES
    @Environment(\.colorScheme) var colorScheme
    
    private let viewModel: IQChatDetailViewModel
    
    private let output: IQChannelsManagerDetailOutput
    
    private let showNavBar: Bool
    
    private var cancellables = Set<AnyCancellable>()

    private let offerLifecycle = IQAnalyticsOfferTrackerLifecycle()
    private var offerTickTimer: Timer?
    private var appBackgroundObserver: NSObjectProtocol?
    private var appActiveObserver: NSObjectProtocol?
    
    private lazy var titleStackView: UIStackView = {
        let stackView: UIStackView = .init(arrangedSubviews: [titleLabel, statusView])
        stackView.spacing = 0
        stackView.axis = .vertical
        return stackView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label: UILabel = .init()
        label.text = viewModel.chatLabel
        
        
        let fontSize = CGFloat(IQStyle.model?.appBar?.titleLabel?.textSize ?? 15)
        let alignment = stringToAlignment(stringAlignment: IQStyle.model?.appBar?.titleLabel?.textAlign) ?? .center
        let isBold = IQStyle.model?.appBar?.titleLabel?.textStyle?.bold ?? true
        let isItalic = IQStyle.model?.appBar?.titleLabel?.textStyle?.italic ?? false
        
        var symbolicTraits: UIFontDescriptor.SymbolicTraits = []

        if isBold {
            symbolicTraits.insert(.traitBold)
        }
        if isItalic {
            symbolicTraits.insert(.traitItalic)
        }

        let systemFont = UIFont.systemFont(ofSize: fontSize)

        if let descriptor = systemFont.fontDescriptor.withSymbolicTraits(symbolicTraits) {
            label.font = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            label.font = systemFont
        }
        
        label.textAlignment = textAlignmentToNSTextAlignment(textAlignment: alignment)
        
        label.textColor = IQStyle.getUIColor(theme: IQStyle.model?.appBar?.titleLabel?.color) ?? UIColor(hex: "242729")
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label: UILabel = .init()
        
        let fontSize = CGFloat(IQStyle.model?.appBar?.statusLabel?.textSize ?? 15)
        let alignment = stringToAlignment(stringAlignment: IQStyle.model?.appBar?.statusLabel?.textAlign) ?? .center
        let isBold = IQStyle.model?.appBar?.statusLabel?.textStyle?.bold ?? false
        let isItalic = IQStyle.model?.appBar?.statusLabel?.textStyle?.italic ?? false
        
        var symbolicTraits: UIFontDescriptor.SymbolicTraits = []

        if isBold {
            symbolicTraits.insert(.traitBold)
        }
        if isItalic {
            symbolicTraits.insert(.traitItalic)
        }

        let systemFont = UIFont.systemFont(ofSize: fontSize)

        if let descriptor = systemFont.fontDescriptor.withSymbolicTraits(symbolicTraits) {
            label.font = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            label.font = systemFont
        }
        
        label.textAlignment = textAlignmentToNSTextAlignment(textAlignment: alignment)
        
        label.textColor = IQStyle.getUIColor(theme: IQStyle.model?.appBar?.statusLabel?.color) ?? UIColor(hex: "919399")
        return label
    }()
    
    private lazy var statusView: UIStackView = {
        let stackView: UIStackView = .init(arrangedSubviews: [statusLabel])
        stackView.axis = .horizontal
        stackView.spacing = 4
        return stackView
    }()
    
    private lazy var backButton: UIButton = {
        let btn: UIButton = .init(frame: .init(x: 0, y: 0, width: 24, height: 24))
        btn.setImage(UIImage(name: "chevron_left"), for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        btn.addTarget(self, action: #selector(onTapBack), for: .touchUpInside)
        return btn
    }()
    
    private lazy var searchButton: UIButton = {
        let btn: UIButton = .init(frame: .init(x: 0, y: 0, width: 24, height: 24))
        btn.setImage(UIImage(name: "search"), for: [])
        btn.imageView?.contentMode = .scaleAspectFit
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        return btn
    }()
    
    private lazy var languageButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.black, for: .normal)
        btn.contentHorizontalAlignment = .right
        btn.frame.size = CGSize(width: 150, height: 20)
        btn.addTarget(self, action: #selector(languageButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    lazy var languageBarButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: languageButton)
    }()
    
    // MARK: - INIT
    init(viewModel: IQChatDetailViewModel,
         output: IQChannelsManagerDetailOutput,
         showNavBar: Bool) {
        self.viewModel = viewModel
        self.output = output
        self.showNavBar = showNavBar
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - LIFECYCLE
    override func setupSwiftUI() {
        IQLog.debug(message: "6")
        
        let hostView: ChatDetailView = .init(delegate: self)
        let controller: UIHostingController = .init(rootView: hostView.environmentObject(viewModel))
        setupConstructedSwiftUI(interactor: controller)
        
        IQLog.debug(message: "7")
    }
    
    // MARK: - LANGUAGE
    private var dropdown: LanguageDropdownView?

    @objc private func languageButtonTapped() {
        if dropdown != nil {
            dropdown?.hide()
            dropdown = nil
            return
        }
        let menu = LanguageDropdownView()
        menu.languages = viewModel.availableLanguages ?? []
        menu.selectedCode = viewModel.selectedLanguage?.code
        menu.onSelect = { [weak self] selected in
            if let code = selected.code {
                self?.output.detailControllerSelectLanguage(didSelect: selected)
                self?.loadLanguageDataFromAppSupport(code)
            }
            
            if let label = selected.name {
                self?.languageButton.setTitle(label, for: .normal)
            }
            
            self?.dropdown = nil
            self?.viewModel.selectedLanguage = selected
            self?.statusLabel.text = self?.resolvedChatSubtitle()
        }
        menu.show(from: languageButton, in: view)
        dropdown = menu
    }
    
    func loadLanguageDataFromAppSupport(_ code: String) {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let fileURL = supportURL.appendingPathComponent("\(code).json")

        IQLog.debug(message: "9")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            IQLog.error(message: "Файл \(code).json не найден")
            return
        }
        let data = try? Data(contentsOf: fileURL)
        IQLog.debug(message: "Язык изменен на \(code)")
        IQLanguageTexts.configure(data)
    }
    
    override func setupNavBar() {
        IQLog.debug(message: "8")
        if let language = UserDefaults.standard.dictionary(forKey: "selectedLanguage") as? [String: String] {
            let code = language["code"]
            let name = language["name"]
            
            if let code = code, let name = name {
                self.loadLanguageDataFromAppSupport(code)
                self.viewModel.selectedLanguage = IQLanguage(code: code, name: name, isDefault: nil, iconURL: nil)
                self.languageButton.setTitle(name, for: .normal)
            } else {
                self.loadLanguageDataFromAppSupport("ru")
            }
        } else {
            self.loadLanguageDataFromAppSupport("ru")
        }
        setupNavigationBarAppearance()
        navigationItem.titleView = titleStackView
        navigationItem.leftBarButtonItem = .init(customView: backButton)
        
        IQLog.debug(message: "10")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = !viewModel.backDismisses
    }
    
    override func bindViewModel() {
        ensureOfferTracking()

        viewModel.$messages
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.ensureOfferTracking()
            }.store(in: &subscriptions)

        viewModel.dismissListener
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }.store(in: &subscriptions)
        
        viewModel.replaceRootListener
            .receive(on: DispatchQueue.main)
            .sink { [weak self] controller in
                guard let self, viewModel.isSkeleton, let navigationController = self.navigationController else { return }
                navigationController.setViewControllers([controller], animated: false)
            }.store(in: &subscriptions)
        
        viewModel.errorListener
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showAlert(message: error.localizedDescription)
            }.store(in: &subscriptions)
        
        viewModel.$inputText
            .dropFirst()
            .sink { [weak self] _ in
                self?.output.detailControllerIsTyping()
            }.store(in: &subscriptions)
        
        viewModel.$messageControlShown
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messageControlShown in
                if(self?.showNavBar ?? true){
                    self?.navigationController?.setNavigationBarHidden(messageControlShown, animated: false)
                }else{
                    self?.navigationController?.setNavigationBarHidden(true, animated: false)
                }
            }.store(in: &subscriptions)
        
        viewModel.$hidesBackButton
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hidesBackButton in
                self?.backButton.isHidden = hidesBackButton
            }.store(in: &subscriptions)
        
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                
                let hasNetwork = state == .authenticated
                self.titleLabel.isHidden = !hasNetwork
                self.statusLabel.text = self.resolvedChatSubtitle(for: state)
                self.refreshTitleView()
            }
            .store(in: &subscriptions)
        
        viewModel.$typingUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self, !viewModel.showBottomTypingBar else { return }
                UIView.transition(with: titleStackView,
                                  duration: 0,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    if (user != nil){
                        self.statusLabel.text = "\(user?.displayName ?? "Оператор") \(IQLanguageTexts.model.operatorTyping ?? "печатает...")"
                    } else {
                        self.statusLabel.text = self.resolvedChatSubtitle()
                    }
                }, completion: nil)
            }.store(in: &subscriptions)
        
        viewModel.$chatLabel
            .receive(on: DispatchQueue.main).sink { [weak self] title in
                self?.titleLabel.text = title
                self?.refreshTitleView()
            }
            .store(in: &cancellables)
        
        viewModel.$chatSubtitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.statusLabel.text = self?.resolvedChatSubtitle()
            }
            .store(in: &cancellables)
        
        viewModel.$chatSettingsLoaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.statusLabel.text = self?.resolvedChatSubtitle()
            }
            .store(in: &cancellables)
        
        viewModel.$availableLanguages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] availableLanguages in
                if(!(availableLanguages?.isEmpty ?? true)){
                    self?.navigationItem.rightBarButtonItem = self?.languageBarButton
                }
                
                if self?.viewModel.selectedLanguage == nil {
                    self?.viewModel.selectedLanguage = availableLanguages?.filter {$0.isDefault == true}.first ?? IQLanguage(code: "ru", name: "Русский", isDefault: true, iconURL: nil)
                    
                    if let newLabel = self?.viewModel.selectedLanguage?.name {
                        self?.languageButton.setTitle(newLabel, for: .normal)
                    }
                }
                
            }
            .store(in: &cancellables)
    }
    
    // MARK: - ACTIONS
    private func refreshTitleView() {
        titleStackView.setNeedsLayout()
        titleStackView.layoutIfNeeded()
        navigationController?.navigationBar.setNeedsLayout()
        navigationItem.titleView = nil
        navigationItem.titleView = titleStackView
    }
    
    private func resolvedChatSubtitle(for state: IQChannelsState = .authenticated) -> String {
        if let subtitle = viewModel.chatSubtitle {
            return subtitle
        }
        guard state == .authenticated else {
            return state.description
        }
        return viewModel.chatSettingsLoaded ? state.description : ""
    }
    
    @objc
    private func onTapBack() {
        if viewModel.backDismisses {
            output.detailControllerDismissChat()
        } else {
            output.detailControllerDidPop()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.offerVisibilityReset.send(())

        if appActiveObserver == nil {
            appActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.viewModel.offerVisibilityReset.send(())
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        offerLifecycle.tracker?.flush(reason: .leftChannel)
    }

    deinit {
        offerTickTimer?.invalidate()
        if let appBackgroundObserver {
            NotificationCenter.default.removeObserver(appBackgroundObserver)
        }
        if let appActiveObserver {
            NotificationCenter.default.removeObserver(appActiveObserver)
        }
    }

    // MARK: - PRIVATE METHODS
    private func ensureOfferTracking() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let context = await self.output.detailControllerOfferTrackingContext()
            switch self.offerLifecycle.refresh(context: context) {
            case .recreated(let tracker):
                self.setupOfferTracking(tracker)
            case .unchanged, .none:
                break
            }
        }
    }

    private func setupOfferTracking(_ tracker: IQAnalyticsViewabilityTracker) {
        tracker.onRead = { [weak self] messageID, durationMs in
            self?.trackOffer(messageID: messageID, readWithDurationMs: durationMs)
        }
        tracker.onSkipped = { [weak self] messageID, reason in
            self?.trackOffer(messageID: messageID, skippedWithReason: reason)
        }

        offerTickTimer?.invalidate()
        offerTickTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak tracker] _ in
            tracker?.tick()
        }
        if let appBackgroundObserver {
            NotificationCenter.default.removeObserver(appBackgroundObserver)
            self.appBackgroundObserver = nil
        }
        appBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak tracker] _ in
            tracker?.flush(reason: .appBackground)
        }
    }

    private func trackOffer(messageID: Int, readWithDurationMs durationMs: Int? = nil, skippedWithReason reason: IQAnalyticsSkipReason? = nil) {
        guard let channel = offerLifecycle.channel,
              let message = viewModel.messages.first(where: { $0.messageID == messageID }) else { return }
        if let durationMs {
            output.detailController(didReadOffer: message, channel: channel, visibleDurationMs: durationMs)
        } else if let reason {
            output.detailController(didSkipOffer: message, channel: channel, reason: reason)
        }
    }

    private func photoSourceDidTap(source: UIImagePickerController.SourceType) {
        switch source {

        case .photoLibrary, .savedPhotosAlbum:

            let gallery = LimitedPhotosViewController()
            gallery.delegate = self

            let nav = UINavigationController(rootViewController: gallery)
            self.present(nav, animated: true)
        case .camera:

            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            present(picker, animated: true)

        @unknown default:
            break
        }
    }
    
    private func fileSourceDidTap(){
        let documentController = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        documentController.delegate = self
        documentController.allowsMultipleSelection = true
        documentController.modalPresentationStyle = .formSheet
        present(documentController, animated: true)
    }
    
    private func displayAttachmentOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(.init(title: IQLanguageTexts.model.gallery ?? "Галерея", style: .default, handler: { _ in
            self.photoSourceDidTap(source: .photoLibrary)
        }))
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(.init(title: IQLanguageTexts.model.camera ?? "Камера", style: .default, handler: { _ in
                self.photoSourceDidTap(source: .camera)
            }))
        }
        alert.addAction(.init(title: IQLanguageTexts.model.file ?? "Файл", style: .default, handler: { _ in
            self.fileSourceDidTap()
        }))
        alert.addAction(.init(title: IQLanguageTexts.model.cancel ?? "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func confirmDocumentSubmission(fileUrls: [URL]) {
        self.output.detailController(didPick: fileUrls.map { ($0, nil) })
        self.viewModel.scrollDown.toggle()
    }
    
    private func showFilePreview(file: IQFile, sessionToken: String) {
        guard let url = file.url else { return }
        if file.type == .image {
            let controller: PreviewViewController = .init(url: url)
            controller.modalPresentationStyle = .overFullScreen
            controller.modalTransitionStyle = .coverVertical
            present(controller, animated: true)
        } else if file.type == .file {
            let controller: FilePreviewController = .init(url: url, fileName: file.name, sessionToken: sessionToken,
                                                          useRussianTrustedRootCA: viewModel.useRussianTrustedRootCA,
                                                          urlSession: viewModel.urlSession)
            present(controller, animated: true)
        }
    }
    
    private func setupNavigationBarAppearance() {
        let backgroundColor = IQStyle.getUIColor(theme: IQStyle.model?.appBar?.background) ?? UIColor(hex: "ffffff")
        
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        titleLabel.textColor = IQStyle.getUIColor(theme: IQStyle.model?.appBar?.titleLabel?.color)
            ?? UIColor(hex: "242729")
        statusLabel.textColor = IQStyle.getUIColor(theme: IQStyle.model?.appBar?.statusLabel?.color)
            ?? UIColor(hex: "919399")
    }
}

// MARK: - CHAT DETAIL VIEW DELEGATE
extension IQChatDetailViewController: ChatDetailViewDelegate {
    func onAttachmentTap() {
        displayAttachmentOptions()
    }
    
    func onDismissChat() {
        output.detailControllerDismissChat()
    }
    
    func onFileTap(_ file: IQFile, sessionToken: String) {
        showFilePreview(file: file, sessionToken: sessionToken)
    }
    
    func onSingleChoiceTap(_ singleChoice: IQSingleChoice) {
        output.detailController(didSelect: singleChoice)
    }
    
    func onProductTap(_ productTap: IQProductTap) {
        output.detailController(didSelect: productTap)
    }
    
    func onActionTap(_ action: IQAction) {
        output.detailController(didSelect: action)
    }
    
    func onMessageAppear(with messageId: Int) {
        output.detailController(didDisplayMessageWith: messageId)
    }

    func onOfferVisibilityChanged(message: IQMessage, visible: Bool) {
        guard message.isMailingOffer else { return }
        if visible {
            offerLifecycle.tracker?.show(id: message.messageID)
        } else {
            offerLifecycle.tracker?.hide(id: message.messageID, reason: .scrolledPast)
        }
    }

    func onLinkTap(url: URL, message: IQMessage?) {
        output.detailController(didTapLink: url, in: message)
    }
    
    func onSendMessage(_ text: String) {
        output.detailController(didSend: text, files: viewModel.selectedFiles, replyToMessage: viewModel.messageToReply?.messageID)
        viewModel.scrollDown.toggle()
    }
    
    func onResendMessage(_ message: IQMessage) {
        output.detailController(didResend: message)
    }
    
    func onCancelUpload(_ message: IQMessage) {
        output.detailController(didCancelUpload: message)
    }
    
    func onCancelSend(_ message: IQMessage) {
        output.detailController(didCancelSend: message)
    }
    
    func onRate(value: Int, ratingId: Int) {
        output.detailController(didRate: value, ratingID: ratingId)
    }
    
    func onSendPoll(value: Int?, answers: [IQRatingPollClientAnswerInput], ratingId: Int, pollId: Int) {
        output.detailController(didSendPoll: value, answers: answers, ratingID: ratingId, pollId: pollId)
    }
    
    func onPollIgnored(ratingId: Int, pollId: Int) {
        output.detailController(didPollIgnored: ratingId, pollId: pollId)
    }
    
    func onChangeSegment(_ message: IQMessage) {
        output.detailController(didChangeSegment: message)
    }
}

// MARK: - PH PICKER DELEGATE
extension IQChatDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        output.detailController(didPick: results)
        viewModel.scrollDown.toggle()
    }
}

// MARK: - IMAGE PICKER DELEGATE
extension IQChatDetailViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let url = info[.imageURL] as? URL {
            output.detailController(didPick: [(url, nil)])
        } else if let image = info[.originalImage] as? UIImage {
            output.detailController(didPick: [(nil, image)])
        }
        viewModel.scrollDown.toggle()
    }
}

extension IQChatDetailViewController: LimitedPhotosViewControllerDelegate {
    func limitedPhotosViewControllerDidPick(images: [(image: UIImage?, url: URL?)]) {

        if !images.isEmpty {
            output.detailController(didPick: images.map { ($0.url, $0.image) })
        }

        viewModel.scrollDown.toggle()
    }
}

// MARK: - DOCUMENT PICKER DELEGATE
extension IQChatDetailViewController: UIDocumentPickerDelegate & UINavigationControllerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        confirmDocumentSubmission(fileUrls: urls)
    }
}


final class LanguageDropdownView: UIView, UITableViewDelegate, UITableViewDataSource {

    var languages: [IQLanguage] = []
    var selectedCode: String?
    var onSelect: ((IQLanguage) -> Void)?

    private let tableView = UITableView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        overrideUserInterfaceStyle = .light
        backgroundColor = .white
        
        layer.cornerRadius = 10
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1.0
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
        tableView.separatorStyle = .none
        tableView.layer.cornerRadius = 10
        tableView.register(LanguageCell.self, forCellReuseIdentifier: "LanguageCell")

        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leftAnchor.constraint(equalTo: leftAnchor),
            tableView.rightAnchor.constraint(equalTo: rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func show(from anchor: UIView, in parent: UIView) {
        guard anchor.superview != nil else { return }
        parent.addSubview(self)

        let anchorFrame = anchor.convert(anchor.bounds, to: parent)
        frame = CGRect(x: anchorFrame.minX,
                       y: anchorFrame.maxY + 8,
                       width: 150,
                       height: CGFloat(min(languages.count, 5)) * 44)
    }

    func hide() {
        removeFromSuperview()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath) as? LanguageCell else {
            return UITableViewCell()
        }

        let lang = languages[indexPath.row]
        let isSelected = lang.code == selectedCode
        cell.configure(with: lang, selected: isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let lang = languages[indexPath.row]
        selectedCode = lang.code
        tableView.reloadData()
        onSelect?(lang)
        hide()
    }
}

final class LanguageCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        nameLabel.font = .systemFont(ofSize: 16)

        let stack = UIStackView(arrangedSubviews: [nameLabel])
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            stack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
            stack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12)
        ])
    }

    func configure(with language: IQLanguage, selected: Bool) {
        nameLabel.text = language.name
        
        if (selected){
            nameLabel.font = .boldSystemFont(ofSize: nameLabel.font.pointSize)
        }
    }
}



protocol LimitedPhotosViewControllerDelegate: AnyObject {
    func limitedPhotosViewControllerDidPick(images: [(image: UIImage?, url: URL?)])
}

final class LimitedPhotosViewController: UIViewController {

    private var assets: [PHAsset] = []
    private var selectedIndexPaths: [IndexPath] = []
    weak var delegate: LimitedPhotosViewControllerDelegate?

    private lazy var sendButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(onSendTapped))
        button.isEnabled = false
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()

        let spacing: CGFloat = 2
        let itemsPerRow: CGFloat = 3

        let width = (UIScreen.main.bounds.width - (itemsPerRow - 1) * spacing) / itemsPerRow

        layout.itemSize = CGSize(width: width, height: width)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(
            PhotoCell.self,
            forCellWithReuseIdentifier: PhotoCell.reuseIdentifier
        )

        return collectionView
    }()

    private let imageManager = PHCachingImageManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = IQLanguageTexts.model.gallery ?? "Галерея"
        navigationItem.rightBarButtonItem = sendButton

        view.backgroundColor = .systemBackground

        setupUI()
        requestAccess()
    }

    private func setupUI() {
        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func requestAccess() {

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {

        case .authorized, .limited:
            loadAssets()

        case .notDetermined:

            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {

                    switch status {

                    case .authorized, .limited:
                        self?.loadAssets()

                    case .denied, .restricted:
                        self?.showAccessDenied()
                        IQLog.debug(message: "Доступ к галерее запрещён")

                    default:
                        break
                    }
                }
            }

        case .denied, .restricted:
            showAccessDenied()
            IQLog.debug(message: "Доступ к галерее запрещён")

        @unknown default:
            break
        }
    }

    private func loadAssets() {

        assets.removeAll()

        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)

        var temp: [PHAsset] = []

        fetchResult.enumerateObjects { asset, _, _ in
            temp.insert(asset, at: 0)
        }

        self.assets = temp
        
        collectionView.reloadData()
    }

    private func showAccessDenied() {

        let alert = UIAlertController(
            title: "Нет доступа",
            message: "Разрешите доступ к фотографиям в настройках",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }
}

extension LimitedPhotosViewController: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        assets.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoCell.reuseIdentifier,
            for: indexPath
        ) as? PhotoCell else {

            return UICollectionViewCell()
        }

        let asset = assets[indexPath.item]
        let selectionIndex = selectedIndexPaths.firstIndex(of: indexPath).map { $0 + 1 }
        cell.setSelected(selectionIndex)

        let size = CGSize(width: 300, height: 300)

        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        ) { image, _ in
            cell.imageView.image = image
        }

        return cell
    }
}

extension LimitedPhotosViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let index = selectedIndexPaths.firstIndex(of: indexPath) {
            selectedIndexPaths.remove(at: index)
        } else {
            selectedIndexPaths.append(indexPath)
        }
        collectionView.reloadItems(at: [indexPath])
        updateSendButton()
    }
    
    private func updateSendButton() {
        if selectedIndexPaths.isEmpty {
            sendButton.title = "Готово"
            sendButton.isEnabled = false
        } else {
            sendButton.title = "Готово (\(selectedIndexPaths.count))"
            sendButton.isEnabled = true
        }
    }
    
    @objc private func onSendTapped() {
        let pickedAssets = selectedIndexPaths.compactMap { assets.indices.contains($0.item) ? assets[$0.item] : nil }
        guard !pickedAssets.isEmpty else { return }
        
        var results: [(image: UIImage?, url: URL?)] = pickedAssets.map { _ in (nil, nil) }
        let lock = NSLock()
        var completed = [Bool](repeating: false, count: pickedAssets.count)
        let group = DispatchGroup()
        
        for (index, asset) in pickedAssets.enumerated() {
            group.enter()
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            
            asset.requestContentEditingInput(with: options) { [weak self] input, _ in
                guard let self else {
                    lock.lock()
                    if !completed[index] {
                        completed[index] = true
                        group.leave()
                    }
                    lock.unlock()
                    return
                }
                let url = input?.fullSizeImageURL
                
                let imageOptions = PHImageRequestOptions()
                imageOptions.deliveryMode = .highQualityFormat
                imageOptions.isNetworkAccessAllowed = true
                
                self.imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: 1000, height: 1000),
                    contentMode: .aspectFill,
                    options: imageOptions
                ) { image, info in
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                    guard !isDegraded else { return }
                    
                    lock.lock()
                    if !completed[index] {
                        completed[index] = true
                        results[index] = (image, url)
                        lock.unlock()
                        group.leave()
                    } else {
                        lock.unlock()
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            delegate?.limitedPhotosViewControllerDidPick(images: results)
            dismiss(animated: true)
        }
    }
}

final class PhotoCell: UICollectionViewCell {

    static let reuseIdentifier = "PhotoCell"

    let imageView: UIImageView = {

        let imageView = UIImageView()

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        return imageView
    }()

    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.isHidden = true
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.systemBlue
        label.clipsToBounds = true
        label.layer.cornerRadius = 10
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        contentView.addSubview(dimView)
        contentView.addSubview(badgeLabel)

        dimView.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            badgeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            badgeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            badgeLabel.widthAnchor.constraint(equalToConstant: 20),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func setSelected(_ index: Int?) {
        if let index {
            badgeLabel.text = "\(index)"
            badgeLabel.isHidden = false
            dimView.isHidden = false
        } else {
            badgeLabel.isHidden = true
            dimView.isHidden = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
