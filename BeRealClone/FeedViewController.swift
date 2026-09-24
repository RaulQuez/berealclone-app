//
//  FeedViewController.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/20/26.
//

import UIKit
import ParseSwift

// Protocol so NewPostViewController can tell us a post was shared without
// the two view controllers needing to know much else about each other.
protocol NewPostViewControllerDelegate: AnyObject {
    func didCreatePost()
}

class FeedViewController: UITableViewController {

    private var posts: [Post] = []
    private let pageSize = 10
    private var isLoadingPosts = false
    private var reachedEndOfFeed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "BeReal Clone"
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .plain, target: self, action: #selector(profileTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))

        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)

        loadPosts(refresh: true)
    }

    private func loadPosts(refresh: Bool) {
        guard !isLoadingPosts else { return }
        isLoadingPosts = true

        let skip = refresh ? 0 : posts.count
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .limit(pageSize)
            .skip(skip)

        query.find(callbackQueue: .main) { [weak self] result in
            guard let self = self else { return }
            self.isLoadingPosts = false
            self.refreshControl?.endRefreshing()

            switch result {
            case .success(let fetchedPosts):
                self.posts = refresh ? fetchedPosts : self.posts + fetchedPosts
                self.reachedEndOfFeed = fetchedPosts.count < self.pageSize
                self.tableView.reloadData()
            case .failure(let error):
                self.showAlert(message: error.message)
            }
        }
    }

    @objc private func refreshFeed() {
        reachedEndOfFeed = false
        loadPosts(refresh: true)
    }

    @objc private func addTapped() {
        let newPostViewController = NewPostViewController()
        newPostViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: newPostViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    @objc private func profileTapped() {
        navigationController?.pushViewController(ProfileViewController(), animated: true)
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

    // Infinite scroll: once the last row is about to be shown, fetch the next page.
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !reachedEndOfFeed, indexPath.row == posts.count - 1 else { return }
        loadPosts(refresh: false)
    }
}

extension FeedViewController: NewPostViewControllerDelegate {
    func didCreatePost() {
        reachedEndOfFeed = false
        loadPosts(refresh: true)
    }
}
