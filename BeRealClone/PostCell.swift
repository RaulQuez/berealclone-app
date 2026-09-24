//
//  PostCell.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/20/26.
//

import UIKit
import ParseSwift

class PostCell: UITableViewCell {

    static let reuseIdentifier = "PostCell"

    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 14
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()

    // Keeps in-flight image downloads from landing on a cell that has since
    // been reused for a different post.
    private var imageDownloadTask: URLSessionDataTask?
    private var avatarDownloadTask: URLSessionDataTask?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutSubviews_setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSubviews_setup() {
        let headerStack = UIStackView(arrangedSubviews: [avatarImageView, usernameLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center

        let labelStack = UIStackView(arrangedSubviews: [headerStack, captionLabel, metaLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        postImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(postImageView)
        contentView.addSubview(labelStack)

        NSLayoutConstraint.activate([
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor),

            avatarImageView.widthAnchor.constraint(equalToConstant: 28),
            avatarImageView.heightAnchor.constraint(equalToConstant: 28),

            labelStack.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 8),
            labelStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            labelStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            labelStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageDownloadTask?.cancel()
        avatarDownloadTask?.cancel()
        postImageView.image = nil
        avatarImageView.image = nil
        usernameLabel.text = nil
        captionLabel.text = nil
        metaLabel.text = nil
    }

    func configure(with post: Post) {
        usernameLabel.text = post.user?.username ?? "Unknown"
        captionLabel.text = post.caption
        captionLabel.isHidden = (post.caption?.isEmpty ?? true)
        metaLabel.text = PostCell.metaText(for: post)
        avatarImageView.image = UIImage(systemName: "person.circle.fill")

        if let url = post.imageFile?.url {
            imageDownloadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.postImageView.image = image
                }
            }
            imageDownloadTask?.resume()
        }

        if let avatarURL = post.user?.profileImage?.url {
            avatarDownloadTask = URLSession.shared.dataTask(with: avatarURL) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.avatarImageView.image = image
                }
            }
            avatarDownloadTask?.resume()
        }
    }

    private static func metaText(for post: Post) -> String {
        var parts: [String] = []

        // Prefer the moment the photo was actually taken; fall back to when
        // the post was saved if that metadata wasn't available.
        if let date = post.photoTakenAt ?? post.createdAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            parts.append(formatter.string(from: date))
        }

        if let locationName = post.locationName {
            parts.append(locationName)
        }

        return parts.joined(separator: " · ")
    }
}
