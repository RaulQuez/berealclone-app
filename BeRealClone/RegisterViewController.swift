//
//  RegisterViewController.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/20/26.
//

import UIKit
import ParseSwift

class RegisterViewController: UIViewController {

    private let usernameField = LoginViewController.makeTextField(placeholder: "Username")
    private let emailField = LoginViewController.makeTextField(placeholder: "Email")
    private let passwordField = LoginViewController.makeTextField(placeholder: "Password", isSecure: true)

    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .label
        button.setTitleColor(.systemBackground, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Sign Up"
        emailField.keyboardType = .emailAddress

        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)

        layoutSubviews()
    }

    private func layoutSubviews() {
        let stackView = UIStackView(arrangedSubviews: [usernameField, emailField, passwordField, signUpButton, activityIndicator])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            usernameField.heightAnchor.constraint(equalToConstant: 44),
            emailField.heightAnchor.constraint(equalToConstant: 44),
            passwordField.heightAnchor.constraint(equalToConstant: 44),
            signUpButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func signUpTapped() {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(message: "Please fill in a username and password.")
            return
        }

        view.endEditing(true)
        activityIndicator.startAnimating()

        var newUser = User()
        newUser.username = username
        newUser.password = password
        newUser.email = emailField.text?.isEmpty == false ? emailField.text : nil

        newUser.signup { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                switch result {
                case .success:
                    self?.goToFeed()
                case .failure(let error):
                    self?.showAlert(message: error.message)
                }
            }
        }
    }

    private func goToFeed() {
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else { return }
        sceneDelegate.showFeed()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
