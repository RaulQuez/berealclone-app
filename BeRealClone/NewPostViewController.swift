//
//  NewPostViewController.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/20/26.
//

import UIKit
import PhotosUI
import Photos
import CoreLocation
import ParseSwift

class NewPostViewController: UIViewController {

    weak var delegate: NewPostViewControllerDelegate?

    private var selectedImage: UIImage?
    private var selectedAssetDate: Date?
    private var selectedAssetLocation: CLLocation?

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .secondarySystemBackground
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let choosePhotoLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to choose a photo"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let captionField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Add a caption (optional)"
        textField.borderStyle = .roundedRect
        return textField
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "New Post"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .done, target: self, action: #selector(shareTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(choosePhotoTapped))
        imageView.addGestureRecognizer(tapGesture)

        layoutSubviews()
    }

    private func layoutSubviews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        choosePhotoLabel.translatesAutoresizingMaskIntoConstraints = false
        captionField.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)
        imageView.addSubview(choosePhotoLabel)
        view.addSubview(captionField)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            choosePhotoLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            choosePhotoLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

            captionField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            captionField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            captionField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            captionField.heightAnchor.constraint(equalToConstant: 44),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func choosePhotoTapped() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func shareTapped() {
        guard let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.7) else { return }

        view.endEditing(true)
        navigationItem.rightBarButtonItem?.isEnabled = false
        activityIndicator.startAnimating()

        var post = Post()
        post.user = User.current
        post.imageFile = ParseFile(name: "photo.jpg", data: imageData)
        post.caption = captionField.text?.isEmpty == false ? captionField.text : nil
        post.photoTakenAt = selectedAssetDate
        post.latitude = selectedAssetLocation?.coordinate.latitude
        post.longitude = selectedAssetLocation?.coordinate.longitude

        // Reverse-geocode the photo's coordinates into a readable place name
        // (e.g. "Miami") before saving, if we have a location to work with.
        if let location = selectedAssetLocation {
            CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
                post.locationName = placemarks?.first?.locality
                self?.save(post)
            }
        } else {
            save(post)
        }
    }

    private func save(_ post: Post) {
        post.save(callbackQueue: .main) { [weak self] result in
            self?.activityIndicator.stopAnimating()
            switch result {
            case .success:
                self?.delegate?.didCreatePost()
                self?.dismiss(animated: true)
            case .failure(let error):
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                self?.showAlert(message: error.message)
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension NewPostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.imageView.image = image
                self?.choosePhotoLabel.isHidden = true
                self?.selectedImage = image
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }

        // The picker itself doesn't expose metadata, so we look the asset back
        // up by its identifier to grab the date/location it was taken.
        guard let assetIdentifier = result.assetIdentifier else { return }
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            fetchAssetMetadata(for: assetIdentifier)
        } else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                guard newStatus == .authorized || newStatus == .limited else { return }
                self?.fetchAssetMetadata(for: assetIdentifier)
            }
        }
    }

    private func fetchAssetMetadata(for assetIdentifier: String) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = assets.firstObject else { return }
        selectedAssetDate = asset.creationDate
        selectedAssetLocation = asset.location
    }
}
