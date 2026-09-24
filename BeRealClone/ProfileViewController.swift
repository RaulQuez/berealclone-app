//
//  ProfileViewController.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/24/26.
//

import UIKit
import ParseSwift

class ProfileViewController: UITableViewController {

    private var posts: [Post] = []

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Profile"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))

        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
        buildHeaderView()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(loadOwnPosts), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Picks up any bio/profile picture change made in EditProfileViewController.
        populateHeader()
        loadOwnPosts()
    }

    private func buildHeaderView() {
        let header = UIView()

        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Log Out", for: .normal)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [profileImageView, usernameLabel, bioLabel, logoutButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.setCustomSpacing(16, after: profileImageView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stackView)

        let imageSize: CGFloat = 96
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: imageSize),
            profileImageView.heightAnchor.constraint(equalToConstant: imageSize),

            stackView.topAnchor.constraint(equalTo: header.topAnchor, constant: 24),
            stackView.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -24),
            stackView.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -24)
        ])

        profileImageView.layer.cornerRadius = imageSize / 2
        tableView.tableHeaderView = header

        // populateHeader() fills in the text and resizes the header to fit it.
        populateHeader()
    }

    // tableHeaderView doesn't auto-size to its Auto Layout content, and the
    // bio can be one line or several, so we measure it against the device
    // width every time its text changes and hand the table the real height.
    private func resizeHeaderToFitContent() {
        guard let header = tableView.tableHeaderView else { return }
        let targetWidth = UIScreen.main.bounds.width
        header.frame = CGRect(x: 0, y: 0, width: targetWidth, height: header.frame.height)
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let fittingSize = header.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        header.frame = CGRect(x: 0, y: 0, width: targetWidth, height: fittingSize.height)
        tableView.tableHeaderView = header
    }

    private func populateHeader() {
        usernameLabel.text = User.current?.username
        bioLabel.text = User.current?.bio
        bioLabel.isHidden = (User.current?.bio?.isEmpty ?? true)
        resizeHeaderToFitContent()

        guard let url = User.current?.profileImage?.url else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }

    @objc private func loadOwnPosts() {
        guard let currentUser = User.current else { return }

        let query = Post.query("user" == currentUser)
            .include("user")
            .order([.descending("createdAt")])

        query.find(callbackQueue: .main) { [weak self] result in
            self?.refreshControl?.endRefreshing()
            switch result {
            case .success(let posts):
                self?.posts = posts
                self?.tableView.reloadData()
            case .failure(let error):
                self?.showAlert(message: error.message)
            }
        }
    }

    @objc private func editTapped() {
        navigationController?.pushViewController(EditProfileViewController(), animated: true)
    }

    @objc private func logoutTapped() {
        User.logout { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    guard let sceneDelegate = self?.view.window?.windowScene?.delegate as? SceneDelegate else { return }
                    sceneDelegate.showLogin()
                case .failure(let error):
                    self?.showAlert(message: error.message)
                }
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Oops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Table view

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifier, for: indexPath) as! PostCell
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}
