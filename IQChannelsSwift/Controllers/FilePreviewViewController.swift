//
//  FilePreviewViewController.swift
//  IQChannelsSwift
//
//  Created by Muhammed Aralbek on 05.06.2024.
//

import UIKit
import WebKit
import MobileCoreServices
import UniformTypeIdentifiers

class FilePreviewController: UIViewController, WKNavigationDelegate, URLSessionDelegate, UIDocumentPickerDelegate {
    
    private var sessionToken: String
    private var webView: WKWebView!
    private var documentUrl: URL
    private var fileName: String?
    private var downloadButton: UIButton!
    private var dismissButton: UIButton!
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    // Initialize with a URL
    init(url: URL, fileName: String?, sessionToken: String) {
        self.sessionToken = sessionToken
        self.documentUrl = url
        self.fileName = fileName
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .coverVertical
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the web view
        setupWebView()
        
        // Setup the download button
        setupDownloadButton()
    }
    
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        let headerView = UIView()
        headerView.backgroundColor = .white
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 110),

            webView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        var request = URLRequest(url: documentUrl)
        request.setValue("client-session=\(sessionToken)", forHTTPHeaderField: "Cookie")
        webView.load(request)
    }
    
    private func setupDownloadButton() {
        dismissButton = UIButton(type: .system)
        dismissButton.setImage(.init(systemName: "xmark.circle"), for: .normal)
        dismissButton.tintColor = .white
        dismissButton.backgroundColor = .gray.withAlphaComponent(0.8)
        dismissButton.layer.cornerRadius = 20
        dismissButton.clipsToBounds = true
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)

        downloadButton = UIButton(type: .system)
        downloadButton.setImage(UIImage(systemName: "arrow.down.circle"), for: .normal)
        downloadButton.tintColor = .white
        downloadButton.backgroundColor = .gray.withAlphaComponent(0.8)
        downloadButton.layer.cornerRadius = 20
        downloadButton.clipsToBounds = true
        downloadButton.addTarget(self, action: #selector(downloadDocument), for: .touchUpInside)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(downloadButton)
        
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dismissButton.heightAnchor.constraint(equalToConstant: 40),
            dismissButton.widthAnchor.constraint(equalToConstant: 40),
        ])
        
        NSLayoutConstraint.activate([
            downloadButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            downloadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            downloadButton.heightAnchor.constraint(equalToConstant: 40),
            downloadButton.widthAnchor.constraint(equalToConstant: 40),
        ])

    }
    
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod
                == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(
            .useCredential,
            URLCredential(trust: serverTrust)
        )
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod
                == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(
            .useCredential,
            URLCredential(trust: serverTrust)
        )
    }
    
    @objc private func dismissButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func downloadDocument() {
        // Assuming the document is not protected by copyright or other restrictions
        var request = URLRequest(url: documentUrl)
        request.setValue("client-session=\(sessionToken)", forHTTPHeaderField: "Cookie")

        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        let downloadTask = session.downloadTask(with: request) { [weak self] url, response, error in
            guard let self, let url, let data = try? Data(contentsOf: url), error == nil else {
                self?.showAlert(message: IQLanguageTexts.model.fileSavedError ?? "Не удалось загрузить файл")
                return
            }
            
            let type: UTType = .init(self.documentUrl.lastPathComponent) ?? .data
            let savedURL = documentsDirectory.appendingPathComponent(fileName ?? response?.suggestedFilename ?? "downloadedFile", conformingTo: type)
            FileManager.default.createFile(atPath: savedURL.path, contents: data)
            
            DispatchQueue.main.async {
                let documentPicker = UIDocumentPickerViewController(forExporting: [savedURL], asCopy: true)
                documentPicker.delegate = self
                self.present(documentPicker, animated: true)
            }
        }
        
        downloadTask.resume()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let selectedURL = urls.first {
            let title = IQLanguageTexts.model.fileSavedTitle ?? "Успешно!"
            let message = IQLanguageTexts.model.fileSavedText ?? "Файл успешно сохранен."
            self.showAlert(title: title, message: message)
        }
    }
}
