//
//  EditProfileViewController.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/24/26.
//

import UIKit
import PhotosUI
import ParseSwift

class EditProfileViewController: UIViewController {

    private var selectedImage: UIImage?

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let changePhotoLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to change photo"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let bioTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        return textView
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Edit Profile"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))

        bioTextView.text = User.current?.bio
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changePhotoTapped))
        profileImageView.addGestureRecognizer(tapGesture)

        layoutSubviews()
        loadCurrentProfileImage()
    }

    private func layoutSubviews() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        changePhotoLabel.translatesAutoresizingMaskIntoConstraints = false
        bioTextView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(profileImageView)
        view.addSubview(changePhotoLabel)
        view.addSubview(bioTextView)
        view.addSubview(activityIndicator)

        let imageSize: CGFloat = 100
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: imageSize),
            profileImageView.heightAnchor.constraint(equalToConstant: imageSize),

            changePhotoLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            changePhotoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            bioTextView.topAnchor.constraint(equalTo: changePhotoLabel.bottomAnchor, constant: 24),
            bioTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            bioTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            bioTextView.heightAnchor.constraint(equalToConstant: 120),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        profileImageView.layer.cornerRadius = imageSize / 2
    }

    private func loadCurrentProfileImage() {
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        guard let url = User.current?.profileImage?.url else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }

    @objc private func changePhotoTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self?.present(picker, animated: true)
            })
        }
        actionSheet.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self?.present(picker, animated: true)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(actionSheet, animated: true)
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        navigationItem.rightBarButtonItem?.isEnabled = false
        activityIndicator.startAnimating()

        var updatedUser = User.current
        updatedUser?.bio = bioTextView.text.isEmpty ? nil : bioTextView.text
        if let imageData = selectedImage?.jpegData(compressionQuality: 0.7) {
            updatedUser?.profileImage = ParseFile(name: "profile.jpg", data: imageData)
        }

        updatedUser?.save(callbackQueue: .main) { [weak self] result in
            self?.activityIndicator.stopAnimating()
            switch result {
            case .success:
                self?.navigationController?.popViewController(animated: true)
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

extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = image
                self?.selectedImage = image
            }
        }
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        profileImageView.image = image
        selectedImage = image
    }
}
