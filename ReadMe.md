`XcodeBenchmark` contains a *large* codebase to measure the compilation time in Xcode.

You are probably familiar with the following question:
> "Should I buy an i5, i7, or even i9 processor for iOS/macOS development?".

`XcodeBenchmark` is initially created for [Max Tech](https://www.youtube.com/channel/UCptwuAv0XQHo1OQUSaO6NHw) YouTube channel to compare the performance of new iMacs 2020.

I believe the results will help developers to make the right *cost/performance* trade-off decision when choosing their next Mac.

## Score

|        Device        |           CPU          | RAM | SSD | Xcode |  macOS  | Time(sec) |
|:--------------------:|:----------------------:|:---:|:---:|:-----:|:-------:|:---------:|
|     iMac 27" 2020    |   i9 3.6 GHz 10-core   |  64 | 512 |  11.6 | 10.15.6 |    217    |
|     iMac 27" 2020    |    i7 3.8 GHz 8-core   |  64 | 512 |  11.6 | 10.15.6 |    229    |
|     iMac 27" 2020    |    i7 3.8 GHz 8-core   |  32 | 512 |  11.6 | 10.15.6 |    229    |
|   iMac Pro 27" 2017  |   Xeon 3.2 GHz 8-core  |  32 | 1TB |  11.6 | 10.15.6 |    263    |
| MacBook Pro 16" 2019 |    i9 2,3 GHz 8-core   |  32 | 2TB |  11.6 | 10.15.6 |    328    |
| Mac Mini 2018        | i5-8500B, 3 GHz 6-core |   8 | 512 |  11.7 | 10.15.6 |    383    |
|      Hackintosh      | i5-8400 2,8 Ghz 6-core |  32 | 512 |  11.6 | 10.15.6 |    409    |
| iMac 21.5" 2017      | i7-7700 3.60GHz,4-core |  16 | 1TB |  11.7 | 10.16.6 |    419    |
| MacBook Pro 15" 2018 |    i7 2,6 GHz 6-core   |  16 | 512 |  11.6 | 10.15.6 |    440    |
| MacBook Pro 15" 2017 |    i7 2,9 GHz 4-core   |  16 | 512 |  11.6 | 10.15.6 |    583    |

## Set up

- Download and install [Xcode](https://apps.apple.com/us/app/xcode/id497799835).
- Open Xcode and install `additional tools` (Xcode should suggest it automatically).
- Perform `defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES` in `Terminal` to show build time in the Xcode progress bar.
- Download and unarchive [XcodeBenchmark](https://github.com/devMEremenko/XcodeBenchmark/archive/master.zip) project.

## Before each test

1. Select `XcodeBenchmark` -> `Generic iOS Device` in the top left corner. 
2. Close `XcodeBenchmark.xcworkspace` project.
2. Remove the `DerivedData` folder, by selecting Finder, pressing `shift + command + G` and paste in the path: `~/Library/Developer/Xcode`, select the `DerivedData` folder and delete it.
3. Disconnect network cable and turn off WiFi and make sure to disable all software running at startup, i.e. Spotify.
4. Make sure `Login Items` list is empty: System Preferences -> Users and Groups -> User -> Login Items.
5. Reboot and cool down your Mac.
6. Connect to the power adapter if you use MacBook.

## Running a test

1. Open `XcodeBenchmark.xcworkspace` (please do not confuse with `xcproject`).
2. Press `Command B` to start compilation.

**Important: Start compilation as quickly as possible once you opened a project**

## FAQ

**Q: What's inside?**

The framework that incudes **42** popular CocoaPods libraries and **70+** dependencies in total.

| Language      | files | blank  | comment | code   |
|---------------|-------|--------|---------|--------|
| C/C++ Header  | 2785  | 58618  | 143659  | 215644 |
| C++           | 750   | 24771  | 30788   | 182663 |
| Objective C   | 882   | 27797  | 23183   | 148244 |
| Swift         | 1122  | 21821  | 35225   | 113945 |
| C             | 390   | 15064  | 23319   | 84119  |
| Objective C++ | 69    | 2980   | 2026    | 15561  |
| Markdown      | 61    | 4865   | 1       | 15131  |
| XML           | 144   | 1022   | 10      | 13047  |
| Bourne Shell  | 3     | 244    | 209     | 1321   |
| JSON          | 22    | 1      | 0       | 1114   |
| Pascal        | 2     | 87     | 185     | 180    |
| YAML          | 1     | 0      | 0       | 5      |
| SUM:          | 6231  | 157270 | 258605  | 790974 |

**Q: What do the results mean?**
1. First of all, the project is **huge**. I think the majority of projects have a smaller size.
2. The results show *relative* performance in Xcode compared to other Macs under the same conditions.

**Q: Why is CocoaPods not excluded from git-repo?**
- The project is also used by non-programmers. Let's *keep it simple*.

## Contribution

1. Submit a pull request and add a row to the `Score` section. Make sure the `Time` column is still sorted after insertion.
2. [Open an issue](https://github.com/devMEremenko/XcodeBenchmark/issues/new/choose) and include all info to fill the `Score` section.

## Contributors

- [Maxim Eremenko](https://www.linkedin.com/in/maxim-eremenko/) 
- [Max Tech](https://www.youtube.com/channel/UCptwuAv0XQHo1OQUSaO6NHw) YouTube channel
- [@bitsmakerde](https://github.com/bitsmakerde)
- [@ivanfeanor](https://github.com/ivanfeanor)
