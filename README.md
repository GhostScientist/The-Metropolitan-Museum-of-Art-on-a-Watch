# The Tiny Met

A watchOS app for exploring the Metropolitan Museum of Art collection, searching departments, inspecting artwork, and keeping local favorites.

## Development setup

- Use a Mac with Xcode 16 or newer, its command-line tools selected in Xcode Settings > Locations, and an installed watchOS simulator runtime.
- The app supports watchOS 10 and newer. Open `The Tiny Met.xcodeproj`, select the shared **The Tiny Met Watch App** scheme, and choose an Apple Watch simulator.
- Simulator builds do not need an Apple developer account. For a physical watch, choose your own development team and unique bundle identifiers in Signing & Capabilities for both app targets; pair the watch and enable Developer Mode.
- No API keys, third-party packages, or backend setup are required.

Run these commands from your checkout root:

```sh
swift test
xcodebuild \
  -project "The Tiny Met.xcodeproj" \
  -scheme "The Tiny Met Watch App" \
  -configuration Debug \
  -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath /tmp/TinyMetDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

The Swift package test target exercises the app's shared core sources independently of the watch UI. Use `swift test` for these tests, not the watch scheme's Test action. Tests use injected clients/sessions rather than the live Met API. SwiftUI previews also use a fixture client. GitHub Actions runs the core tests and an unsigned watch simulator build on macOS.

## App behavior and manual checks

- Browse departments or submit a search; clearing the search restores department browsing. Network errors show a retry action without discarding already loaded pages.
- Open **Favorites** from the home screen even if departments cannot load. Save up to 100 favorites; they are device-local, with no account or synchronization.
- Artwork previews use smaller images; inspection loads the full-size image when available. Failed images can be retried.
- Metadata and images use bounded caches (including a 30 MiB image cache). Cached content may be evicted, so not every previously viewed image is guaranteed to remain available offline. Large artwork is downsampled for the watch display, and oversized downloads show an error rather than exhausting memory.

Before shipping, check a simulator or device with connectivity disabled: home-screen retry, access to saved favorites, cached versus uncached images, and retry after reconnecting. Also check rapid search changes, clearing a search, scrolling across page boundaries, and zooming on a small watch display. Core tests do not replace these UI checks.

## Privacy policy

### Effective Date: 09/06/2026

This Privacy Policy outlines how The Tiny Met handles your data.

### Information Collection
The Tiny Met does not require an account or collect personal details or analytics. Favorite artwork selections are stored only on your device. The app makes requests to the Metropolitan Museum of Art's public API and artwork image servers to fetch the content you browse.

### Third-Party Libraries and Services
The Tiny Met uses the Metropolitan Museum of Art's Open Access API and artwork image servers. These read-only requests include the search terms, department identifiers, or artwork URLs needed to retrieve content. As with other internet requests, the receiving service can see network information such as your IP address. Favorites are not uploaded or synchronized by the app, and the app has no third-party analytics libraries.

### Data Usage
The Tiny Met does not use your information for analytics, advertising, or user profiling. Local metadata and image caches improve performance and are bounded in size. Favorites persist locally until you remove them or delete the app; cached content may be evicted. Saving a favorite may fetch its preview image, but does not send a favorites list to any service.

### Data Security
Favorites and cached artwork are stored in the app's local storage. All interactions with the Met's API and artwork image downloads use secure HTTPS connections.

### Children's Privacy
The Tiny Met is suitable for users of all ages. We do not knowingly collect any personal information from children or any other users.

### Changes to This Privacy Policy
If we decide to update or modify this Privacy Policy, we will post the changes within the app and update the "Effective Date" at the top of this policy.

### Contact Me
If you have any questions, concerns, or suggestions regarding this Privacy Policy, please contact me at dakotackim@gmail.com

By using The Tiny Met, you acknowledge that you have read and understood this Privacy Policy and agree to its terms.

### Attribution
This application uses the Metropolitan Museum of Art Collection API but is not endorsed or certified by The Metropolitan Museum of Art.