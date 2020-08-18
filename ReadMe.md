`XcodeBenchmark` contains a *large* codebase to measure the compilation time in Xcode.

You are probably familiar with the following question:
> "Should I buy an i5, i7, or even i9 processor for iOS/macOS development?".

`XcodeBenchmark` is initially created for [Max Tech](https://www.youtube.com/channel/UCptwuAv0XQHo1OQUSaO6NHw) YouTube channel to compare the performance of new iMacs 2020.

I believe the results will help developers to make the right *cost/performance* trade-off decision when choosing their next Mac.

## Set up

- Download and install [Xcode](https://apps.apple.com/us/app/xcode/id497799835).
- Open Xcode and install `additional tools` (Xcode should suggest it automatically).
- Perform `defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES` in `Terminal` to show build time in the Xcode progress bar.
- Download and unarchive [XcodeBenchmark](https://github.com/devMEremenko/XcodeBenchmark/archive/master.zip) project.

## Before each test

1. Select `XcodeBenchmark` -> `Generic iOS Device` in the top left corner. 
2. Close `XcodeBenchmark.xcworkspace` project.
2. Remove `DerivedData` folder at `/Users/username/Library/Developer/Xcode/DerivedData`.
3. Reboot and cool down your Mac.
4. Connect to the power adapter if you use MacBook.
5. Make sure `Login Items` list is empty: System Preferences -> Users and Groups -> User -> Login Items.

## Running a test

1. Open `XcodeBenchmark.xcworkspace` (please do not confuse with `xcproject`).
2. Press `Command B` to start compilation.

**Important: Start compilation as quickly as possible once you opened a project**

## FAQ

**Q: What's inside?**
- The framework that incudes **42** popular CocoaPods libraries and **70+** dependencies in total.

**Q: What do the results mean?**
1. First of all, the project is **huge**. I think the average project does **not** have so many dependencies.
2. The results give an **approximate** performance in ideal conditions.

**Q: Why CocoaPods are included?**
- The project is also used by non-programmers. Let's *keep it simple*.

