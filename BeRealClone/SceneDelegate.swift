//
//  SceneDelegate.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/20/26.
//

import UIKit
import ParseSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // Parse-Swift restores the logged-in user (if any) from the keychain
        // before this runs, so we can send people straight to the feed.
        if User.current != nil {
            showFeed(animated: false)
            verifySession()
        } else {
            showLogin(animated: false)
        }

        window.makeKeyAndVisible()
    }

    // Called after a successful login/signup.
    func showFeed(animated: Bool = true) {
        let feedViewController = FeedViewController()
        let navigationController = UINavigationController(rootViewController: feedViewController)
        transition(to: navigationController, animated: animated)
    }

    // Called after logging out.
    func showLogin(animated: Bool = true) {
        let loginViewController = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginViewController)
        transition(to: navigationController, animated: animated)
    }

    // The keychain can hold onto a session token the server no longer
    // recognizes (revoked, expired, user deleted). Confirming it against the
    // server on launch keeps a stale local session from silently sticking around.
    private func verifySession() {
        User.current?.fetch { [weak self] result in
            if case .failure = result {
                DispatchQueue.main.async {
                    self?.showLogin()
                }
            }
        }
    }

    private func transition(to rootViewController: UIViewController, animated: Bool) {
        guard let window = window else { return }
        window.rootViewController = rootViewController
        guard animated else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
