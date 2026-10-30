//
//  PreFillMsgView.swift
//  IQChannelsSwift
//
//  Created by Mikhail Zinkov on 18.01.2025.
//

import UIKit
import SwiftUI
import PhotosUI
import SafariServices
import UniformTypeIdentifiers
import IQChannelsSwift

// MARK: - Attachment Model

private struct SelectedAttachment {
    let file: DataFile
    let preview: UIImage?
}

// MARK: - Attachment Cell

private final class AttachmentCell: UICollectionViewCell {

    static let identifier = "AttachmentCell"

    var onDelete: (() -> Void)?

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let deleteButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .secondarySystemBackground

        nameLabel.font = .systemFont(ofSize: 10)
        nameLabel.textAlignment = .center
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.numberOfLines = 1

        deleteButton.setImage(
            UIImage(systemName: "xmark.circle.fill"),
            for: .normal
        )
        deleteButton.tintColor = .systemRed
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 12

        deleteButton.addTarget(
            self,
            action: #selector(deleteTapped),
            for: .touchUpInside
        )

        [
            imageView,
            nameLabel,
            deleteButton
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([

            imageView.topAnchor.constraint(
                equalTo: contentView.topAnchor
            ),
            imageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            imageView.heightAnchor.constraint(
                equalToConstant: 85
            ),

            nameLabel.topAnchor.constraint(
                equalTo: imageView.bottomAnchor,
                constant: 4
            ),
            nameLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            nameLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            nameLabel.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),

            deleteButton.topAnchor.constraint(
                equalTo: imageView.topAnchor,
                constant: 3
            ),
            deleteButton.trailingAnchor.constraint(
                equalTo: imageView.trailingAnchor,
                constant: -3
            ),
            deleteButton.widthAnchor.constraint(
                equalToConstant: 24
            ),
            deleteButton.heightAnchor.constraint(
                equalToConstant: 24
            )
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with attachment: SelectedAttachment) {

        if let preview = attachment.preview {
            imageView.image = preview
            imageView.contentMode = .scaleAspectFill
        } else {
            imageView.image = UIImage(systemName: "doc.fill")
            imageView.contentMode = .center
            imageView.tintColor = .secondaryLabel
        }

        nameLabel.text = attachment.file.filename
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}

// MARK: - PreFillMsgView

class PreFillMsgView: UIViewController {

    private var selectedFiles: [SelectedAttachment] = []

    var configuration: IQLibraryConfigurationProtocol?

    var setServer: ((IQPreFillMessages?) -> Void)?

    // MARK: - Message Field

    private lazy var messageField: UITextField = {
        let field = UITextField()

        field.borderStyle = .roundedRect
        field.placeholder = "message"
        field.text = "test message"
        field.addToolbar()

        return field
    }()

    // MARK: - Choose Files Button

    private lazy var chooseFiles: UIButton = {
        let button = UIButton()

        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Выбрать файлы", for: .normal)

        button.addTarget(
            self,
            action: #selector(showAttachChooser),
            for: .touchUpInside
        )

        return button
    }()

    // MARK: - Selected Files Label

    private lazy var selectedFilesLabel: UILabel = {
        let label = UILabel()

        label.text = "Выбранные файлы:"
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Attachments Collection View

    private lazy var attachmentsCollectionView: UICollectionView = {

        let layout = UICollectionViewFlowLayout()

        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 90, height: 110)
        layout.minimumLineSpacing = 10

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.dataSource = self

        collectionView.register(
            AttachmentCell.self,
            forCellWithReuseIdentifier: AttachmentCell.identifier
        )

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        return collectionView
    }()

    // MARK: - Send Button

    private lazy var sendMsg: UIButton = {
        let button = UIButton()

        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.setTitle("Отправить", for: .normal)

        button.addTarget(
            self,
            action: #selector(openChat),
            for: .touchUpInside
        )

        return button
    }()

    // MARK: - Stack View

    private lazy var stackView: UIStackView = {

        let view = UIStackView(arrangedSubviews: [
            messageField,
            chooseFiles,
            selectedFilesLabel,
            attachmentsCollectionView,
            sendMsg
        ])

        view.spacing = 16
        view.distribution = .fill
        view.axis = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setDismissKeyboardOnTap()

        view.addSubview(stackView)
        view.backgroundColor = .white

        NSLayoutConstraint.activate([

            stackView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),

            stackView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -16
            ),

            stackView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),

            messageField.heightAnchor.constraint(
                equalToConstant: 62
            ),

            chooseFiles.heightAnchor.constraint(
                equalToConstant: 50
            ),

            attachmentsCollectionView.heightAnchor.constraint(
                equalToConstant: 110
            ),

            sendMsg.heightAnchor.constraint(
                equalToConstant: 50
            )
        ])
    }

    // MARK: - Keyboard

    private func setDismissKeyboardOnTap() {

        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        tap.cancelsTouchesInView = false

        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Open Chat

    @objc private func openChat() {

        let textMsg = messageField.text ?? ""

        let preFillMessages = IQPreFillMessages(
            textMsg: [textMsg],
            fileMsg: selectedFiles.map { $0.file }
        )

        setServer?(preFillMessages)

        configuration?.login(.anonymous)

        if let navigationController = configuration?.getViewController() {
            present(navigationController, animated: true)
        }

        messageField.text = ""
        selectedFiles.removeAll()
        attachmentsCollectionView.reloadData()
    }

    // MARK: - Attachment Chooser

    @objc private func showAttachChooser() {
        displayAttachmentOptions()
    }

    private func displayAttachmentOptions() {

        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        alert.addAction(.init(
            title: "Галерея",
            style: .default,
            handler: { [weak self] _ in
                self?.photoSourceDidTap(source: .photoLibrary)
            }
        ))

        alert.addAction(.init(
            title: "Файл",
            style: .default,
            handler: { [weak self] _ in
                self?.fileSourceDidTap()
            }
        ))

        alert.addAction(.init(
            title: "Отмена",
            style: .cancel
        ))

        present(alert, animated: true)
    }

    // MARK: - Photo Library

    private func photoSourceDidTap(
        source: UIImagePickerController.SourceType
    ) {

        switch source {

        case .photoLibrary, .savedPhotosAlbum:

            var configuration = PHPickerConfiguration(
                photoLibrary: .shared()
            )

            configuration.selectionLimit = max(
                0,
                10 - selectedFiles.count
            )

            configuration.preferredAssetRepresentationMode = .current
            configuration.filter = PHPickerFilter.images

            let picker = PHPickerViewController(
                configuration: configuration
            )

            picker.delegate = self

            present(picker, animated: true)

        case .camera:

            let picker = UIImagePickerController()

            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true

            present(picker, animated: true)

        @unknown default:
            break
        }
    }

    // MARK: - Document Picker

    private func fileSourceDidTap() {

        let documentController = UIDocumentPickerViewController(
            forOpeningContentTypes: [.data]
        )

        documentController.delegate = self
        documentController.allowsMultipleSelection = true
        documentController.modalPresentationStyle = .formSheet

        present(documentController, animated: true)
    }

    // MARK: - Send Files

    private func sendFiles(items: [(URL?, UIImage?)]) {

        let remainingCount = max(
            0,
            10 - selectedFiles.count
        )

        for (url, image) in items.prefix(remainingCount) {

            if let url {

                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }

                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                guard let data = try? Data(contentsOf: url) else {
                    continue
                }

                let file = DataFile(
                    data: data,
                    filename: url.lastPathComponent
                )

                selectedFiles.append(
                    SelectedAttachment(
                        file: file,
                        preview: UIImage(data: data)
                    )
                )

            } else if let image {

                guard let data = image.dataRepresentation(
                    withMaxSizeMB: CGFloat(30)
                ) else {
                    continue
                }

                let file = DataFile(
                    data: data,
                    filename: "image.jpeg"
                )

                selectedFiles.append(
                    SelectedAttachment(
                        file: file,
                        preview: image
                    )
                )
            }
        }

        updateSelectedFilesLabel()
    }

    // MARK: - Send Images

    private func sendImages(result: [PHPickerResult]) {

        Task {

            let remainingCount = max(
                0,
                10 - selectedFiles.count
            )

            for item in result.prefix(remainingCount) {

                guard let data = await item.data(
                    maxSizeInMB: CGFloat(30)
                ) else {
                    continue
                }

                let isGif = item.itemProvider.hasItemConformingToTypeIdentifier(
                    UTType.gif.identifier
                )

                let file = DataFile(
                    data: data,
                    filename: isGif ? "image.gif" : "image.jpeg"
                )

                selectedFiles.append(
                    SelectedAttachment(
                        file: file,
                        preview: UIImage(data: data)
                    )
                )
            }

            updateSelectedFilesLabel()
        }
    }

    // MARK: - Update Selected Files

    private func updateSelectedFilesLabel() {

        let filesText = selectedFiles
            .map { $0.file.filename }
            .joined(separator: ";\n")

        selectedFilesLabel.text = selectedFiles.isEmpty
            ? "Выбранные файлы:"
            : "Выбранные файлы:\n\(filesText)"

        attachmentsCollectionView.reloadData()
    }
}

// MARK: - PHPicker Delegate

extension PreFillMsgView: PHPickerViewControllerDelegate {

    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {

        picker.dismiss(animated: true)

        sendImages(result: results)
    }
}

// MARK: - UIImagePicker Delegate

extension PreFillMsgView: UIImagePickerControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [
            UIImagePickerController.InfoKey: Any
        ]
    ) {

        picker.dismiss(animated: true)

        if let url = info[.imageURL] as? URL {

            sendFiles(items: [(url, nil)])

        } else if let image = info[.editedImage] as? UIImage {

            sendFiles(items: [(nil, image)])
        }
    }
}

// MARK: - Document Picker Delegate

extension PreFillMsgView: UIDocumentPickerDelegate, UINavigationControllerDelegate {

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {

        controller.dismiss(animated: true)

        sendFiles(items: urls.map { ($0, nil) })
    }
}

// MARK: - Collection View Data Source

extension PreFillMsgView: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        selectedFiles.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AttachmentCell.identifier,
            for: indexPath
        ) as! AttachmentCell

        let attachment = selectedFiles[indexPath.item]

        cell.configure(with: attachment)

        cell.onDelete = { [weak self] in

            guard let self else {
                return
            }

            self.selectedFiles.remove(at: indexPath.item)
            self.updateSelectedFilesLabel()
        }

        return cell
    }
}
