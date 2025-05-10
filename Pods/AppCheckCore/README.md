# App Check Core

This library is for internal Google use only. It contains core components of `FirebaseAppCheck`,
from the [`firebase-ios-sdk`](https://github.com/firebase/firebase-ios-sdk) project, for use in
other Google SDKs. External developers should integrate directly with the
[Firebase App Check SDK](https://firebase.google.com/docs/app-check).

## Staging a release

* Determine the next version for release by checking the
  [tagged releases](https://github.com/google/app-check/tags). If the next release will be
  available for both CocoaPods and SPM, ensure that the next release version has been
  incremented accordingly so that the same version tag is used for both CocoaPods and SPM.
* Verify that the releasing version is the latest entry in the [CHANGELOG.md](CHANGELOG.md),
  updating it if necessary.
* Update the version in the podspec to match the latest entry in the [CHANGELOG.md](CHANGELOG.md)
* Checkout the `main` branch and ensure it is up to date
  ```console
  git checkout main
  git pull
  ```
* Add the CocoaPods tag (`{version}` will be the latest version in the [podspec](AppCheckCore.podspec#L3))
  ```console
  git tag CocoaPods-{version}
  git push origin CocoaPods-{version}
  ```
* Push the podspec to the designated repo
  * If this version of GoogleUtilities is intended to launch **before or with** the next Firebase release:
    <details>
    <summary>Push to <b>SpecsStaging</b></summary>

    ```console
    pod repo push --skip-tests --use-json staging AppCheckCore.podspec
    ```

    If the command fails with `Unable to find the 'staging' repo.`, add the staging repo with:
    ```console
    pod repo add staging git@github.com:firebase/SpecsStaging.git
    ```
    </details>
  * Otherwise:
    <details>
    <summary>Push to <b>SpecsDev</b></summary>

    ```console
    pod repo push --skip-tests --use-json dev AppCheckCore.podspec
    ```

    If the command fails with `Unable to find the 'dev' repo.`, add the dev repo with:
    ```console
    pod repo add dev git@github.com:firebase/SpecsDev.git
    ```
    </details>
* Run Firebase CI by waiting until next nightly or adding a PR that touches `Gemfile`.
* To copybara, run the following command on gLinux:
  ```console
  /google/data/ro/teams/copybara/copybara third_party/app_check/copy.bara.sky
  ```

## Publishing

The release process is as follows:
1. [Tag and release for Swift PM](#swift-package-manager)
2. [Publish to CocoaPods](#cocoapods)
3. [Create GitHub Release](#create-github-release)
4. [Perform post release cleanup](#post-release-cleanup)

### Swift Package Manager
  By creating and [pushing a tag](https://github.com/google/app-check/tags)
  for Swift PM, the newly tagged version will be immediately released for public use.
  Given this, please verify the intended time of release for Swift PM.
  * Add a version tag for Swift PM
  ```console
  git tag {version}
  git push origin {version}
  ```
  *Note: Ensure that any inflight PRs that depend on the new `AppCheckCore` version are updated to point to the
  newly tagged version rather than a checksum.*

### CocoaPods
* Publish the newly versioned pod to CocoaPods

  It's recommended to point to the `AppCheckCore.podspec` in `staging` to make sure the correct spec is being published.
  ```console
  pod repo update
  pod trunk push ~/.cocoapods/repos/staging/AppCheckCore/{version}/AppCheckCore.podspec.json
  ```
  *Note: In some cases, it may be acceptable to `pod trunk push` with the `--skip-tests` flag. Please double check with
  the maintainers before doing so.*

  The pod push was successful if the above command logs: `🚀  AppCheckCore ({version}) successfully published`.
  In addition, a new commit that publishes the new version (co-authored by [CocoaPodsAtGoogle](https://github.com/CocoaPodsAtGoogle))
  should appear in the [CocoaPods specs repo](https://github.com/CocoaPods/Specs). Last, the latest version should be displayed
  on [AppCheckCore's CocoaPods page](https://cocoapods.org/pods/AppCheckCore).

### [Create GitHub Release](https://github.com/google/AppCheckCore/releases/new/)
  Update the [release template](https://github.com/google/AppCheckCore/releases/new/)'s **Tag version** and **Release title**
  fields with the latest version. Select the option to auto-generate releases.

  *Don't forget to perform the [post release cleanup](#post-release-cleanup)!*

### Post Release Cleanup
  <details>
  <summary>Clean up <b>SpecsStaging</b></summary>

  ```console
  pwd=$(pwd)
  mkdir -p /tmp/release-cleanup && cd $_
  git clone git@github.com:firebase/SpecsStaging.git
  cd SpecsStaging/
  git rm -rf AppCheckCore/
  git commit -m "Post publish cleanup"
  git push origin main
  rm -rf /tmp/release-cleanup
  cd $pwd
  ```
  </details>

## Contributing

See [Contributing](CONTRIBUTING.md) for more information about contributing to the App Check Core
SDK.

## License

The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
