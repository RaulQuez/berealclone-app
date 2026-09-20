# Project 2 - *BeReal Clone*

Submitted by: **Raul Henriquez**

**BeReal Clone** is an app that lets users register an account, sign in, and post a photo from their library with an optional caption. Once a user has posted, they can browse a feed of everyone's posts, complete with pull-to-refresh, infinite scroll, and the time/location each photo was taken.

Time spent: **X** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] Users see an app icon in the home screen and a styled launch screen.
- [x] User can register a new account
- [x] User can log in with newly created account
- [x] App has a feed of posts when user logs in
- [x] User can upload a new post which takes in a picture from photo library and an optional caption	
- [x] User is able to logout	
 
The following **optional** features are implemented:

- [x] Users can pull to refresh their feed and see a loading indicator
- [x] Users can infinite-scroll in their feed to see past the 10 most recent photos
- [x] Users can see location and time of photo upload in the feed	
- [x] User stays logged in when app is closed and open again	


The following **additional** features are implemented:

- [x] Photo location/time are pulled from the original photo's metadata (not just upload time), then reverse-geocoded into a readable place name (e.g. "Miami") using CoreLocation.

## Video Walkthrough

[TODO] Add a Loom/screen recording link here.

Here is a reminder on how to embed Loom videos on GitHub. Feel free to remove this reminder once you upload your README.

[Guide](https://www.youtube.com/watch?v=GA92eKlYio4).

## Notes

- Parse-Swift is pulled in via Swift Package Manager (already wired up in the Xcode project). Before running, open `AppDelegate.swift` and swap in your own Back4App `applicationId` / `clientKey` (Back4App dashboard > App Settings > Security & Keys).
- The app is built entirely with programmatic UIKit (no storyboards other than the launch screen) — `SceneDelegate` swaps the root view controller between `LoginViewController` and `FeedViewController` based on whether `User.current` is set.
- Reading a photo's original date/location requires photo library permission (`NSPhotoLibraryUsageDescription` is set in `Info.plist`); if that permission is denied, the post still uploads, it just won't have location/time metadata attached.

## License

    Copyright 2026 Raul Henriquez

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
