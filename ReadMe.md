`XcodeBenchmark` contains a *large* codebase to measure the compilation time in Xcode.

You are probably familiar with the following question:
> "Should I buy an i5, i7, or even i9 processor for iOS/macOS development?".

`XcodeBenchmark` is initially created for [Max Tech](https://www.youtube.com/channel/UCptwuAv0XQHo1OQUSaO6NHw) YouTube channel to compare the performance of new iMacs 2020.

I believe the results will help developers to make the right *cost/performance* trade-off decision when choosing their next Mac.

## Note
PR merging will be performed on a best-effort basis.  
If a device you are looking for is not on the list below, check out open [issues](https://github.com/devMEremenko/XcodeBenchmark/issues) and [PRs](https://github.com/devMEremenko/XcodeBenchmark/pulls).

## Xcode 13.0 or above

|        Device        |           CPU           | RAM | SSD | HDD | Xcode |  macOS  | Time(sec) |
|:--------------------:|:-----------------------:|:---:|:---:|:---:|:-----:|:-------:|:---------:|
| Mac Studio 2023      |     M2 Ultra 24-core    |  64 | 1TB |     | 14.3.1| 13.4    |     56    |
| Mac Studio 2022      |     M1 Ultra 20-core    |  64 | 2TB |     |  13.3 | 12.3    |     67    |
| Mac Studio 2022      |     M1 Ultra 20-core    | 128 | 4TB |     | 13.3.1| 12.3.1  |     68    |
| MacBook Pro 16" 2023 |      M2 Max 12-core     |  32 | 1TB |     |  14.2 | 13.2    |     72    |
| MacBook Pro 14" 2023 |      M2 Max 12-core     |  64 | 2TB |     |  14.2 | 13.2    |     72    |
| Mac Mini 2023        |      M2 Pro 12-core     |  32 | 2TB |     |  14.2 | 13.2    |     80    |
| MacBook Pro 14" 2023 |      M2 Pro 10-core     |  32 | 512 |     |  14.2 | 13.2    |     85    |
| Mac Mini 2023        |     M2 Pro 10-core      |  16 | 512 |     | 14.2  | 13.2    |     85    |
| Mac Studio 2022      |     M1 Max 10-core      |  32 | 500 |     | 13.3.1| 12.3.1  |     89    |
| MacBook Pro 14" 2021 |      M1 Max 10-core     |  32 | 2TB |     |  13.1 | 12.0.1  |     90    |
| MacBook Pro 14" 2021 |      M1 Max 10-core     |  64 | 2TB |     |  13.1 | 12.0.1  |     92    |
| MacBook Pro 16" 2021 |      M1 Pro 10-core     |  16 | 1TB |     |  13.2 | 12.2.1  |     92    |
| MacBook Pro 14" 2021 |      M1 Pro 10-core     |  32 | 512 |     |  13.2 | 12.2.1  |     92    |
| MacBook Pro 14" 2021 |      M1 Max 10-core     |  64 | 4TB |     |  13.3 | 12.2.1  |     93    |
| MacBook Pro 16" 2021 |      M1 Max 10-core     |  64 | 4TB |     |  13.1 | 12.0.1  |     93    |
| MacBook Pro 16" 2021 |      M1 Max 10-core     |  32 | 1TB |     |  13.1 | 12.0.1  |     98    |
| MacBook Pro 16" 2021 |      M1 Pro 10-core     |  16 | 512 |     | 13.2.1| 12.2.1  |     98    |
| MacBook Pro 16" 2021 |      M1 Pro 10-core     |  16 | 1TB |     |  13.1 | 12.0.1  |    102    |
| MacBook Pro 14" 2021 |      M1 Pro 8-core      |  16 | 512 |     |  13.1 | 12.0.1  |    109    |
|     Mac mini 2023    |      M2 8-core          |  16 | 512 |     |  14.2 | 13.2    |    111    |
|     Mac mini 2023    |      M2 8-core          |   8 | 256 |     |  14.2 | 13.0    |    112    |
| MacBook Air 13" 2022 |      M2 8-core          |  16 | 512 |     | 13.4.1| 12.5    |    122    |
| MacBook Pro 13" 2020 |      M1 8-core          |  16 | 1TB |     |  13.1 | 12.0.1  |    130    |
|    iMac 24" 2021     |      M1 8-core          |  16 | 512 |     |  13.1 | 12.0.1  |    130    |
|     Mac mini 2020    |      M1 8-core          |   8 | 256 |     |  13.3 | 12.0.1  |    155    |
|     iMac 27" 2019    |    i9 3.6 GHz 8-core    |  64 | 2TB |     |  13.2 | 12.2.1  |    167    |
| MacBook Pro 16" 2019 |    i9 2.3 GHz 8-core    |  16 | 1TB |     |  13.2 | 11.6.1  |    184    |
| MacBook Pro 16" 2019 |    i9 2.4 GHz 8-core    |  64 | 1TB |     |  13.1 | 12.0.1  |    212    |
| MacBook Pro 16" 2019 |    i9 2.4 GHz 8-core    |  32 | 1TB |     |  13.0 | 11.6    |    223    |
|     Mac Pro 2012     |2 x Xeon 3.46 GHz 6-core |  48 | 500 |     |  13.1 | 12.0.1  |    230    |
|     Mac mini 2018    |    i5 3.0 Ghz 6-core    |   8 | 256 |     |  13.0 | 12.0.1  |    235    |
| MacBook Pro 16" 2019 |    i7 2.6 GHz 6-core    |  32 | 512 |     |  13.0 | 11.6    |    248    |
|     Mac Pro 2013     |E5-2697v2 2.7 GHz 12-Core|  64 | 256 |     |  13.1 | 11.6    |    254    |
| MacBook Pro 13" 2020 |    i7 2.3 GHz 4-core    |  32 | 512 |     |  13.1 | 12.0.1  |    255    |
| MacBook Pro 15" 2018 |    i9 2.9 GHz 6-core    |  32 | 1TB |     |  13.0 | 11.6    |    263    |
|     iMac 27" 2015    |    i7 4.0 GHz 4-core    |  32 | 1TB |     |  13.2 | 11.6.7  |    267    |
| MacBook Pro 15" 2019 |    i7 2.6 GHz 6-core    |  32 | 256 |     |  13.2 | 12.0.1  |    277    |
| MacBook Pro 13" 2018 |    i7 2.7 GHz 4-core    |   8 | 256 |     |  13.0 | 11.6    |    336    |
| MacBook Pro 15" 2016 |    i7 2.6 GHz 4-core    |  16 | 256 |     |  13.1 | 12.0.1  |    362    |
|     iMac 27" 2015    |    i5 3.3 GHz 4-core    |  32 | 1TB |     |  13.1 | 11.6    |    400    |
| MacBook Pro 13" 2017 |    i5 2.3 GHz 2-core    |   8 | 256 |     |  13.1 | 11.5.1  |    511    |
| MacBook Pro 13" 2016 |    i5 2.0 GHz 2-core    |   8 | 256 |     |  13.1 | 12.5.1  |    672    |
| MacBook Pro 15" 2015 |    i7 2.8 GHz 4-core    |  16 | 1TB |     |  14.2 | 12.6.2  |    335    |
| MacBook Pro 13" 2015 |    i5 2.7 GHz 2-core    |   8 | 256 |     |  13.2 | 12.0.1  |    860    |

## Xcode 12.5

|        Device        |           CPU           | RAM | SSD | HDD | Xcode |  macOS  | Time(sec) |
|:--------------------:|:-----------------------:|:---:|:---:|:---:|:-----:|:-------:|:---------:|
|    iMac 24" 2021     |      M1 8-core          |  16 | 512 |     |  12.5 | 12.0.1  |    124    |
| MacBook Pro 16" 2019 |    i7 2.6 GHz 6-core    |  16 | 512 |     |  12.5 |   11.4  |    282    |
| MacBook Pro 15" 2015 |    i7 2.5 GHz 4-core    |  16 | 512 |     |  12.5 | 11.2.3  |    361    |

## Xcode 12

|        Device        |           CPU           | RAM | SSD | HDD | Xcode |  macOS  | Time(sec) |
|:--------------------:|:-----------------------:|:---:|:---:|:---:|:-----:|:-------:|:---------:|
|     Mac Pro 2019     |  Xeon 2.5 GHz 28-core   |  96 | 4TB |     |  12.2 | 11.0.1  |    90     |
|     Mac mini 2020    |        M1 8-core        |  16 | 1TB |     |  12.2 |   11.0  |    116    |
| MacBook Pro 13" 2020 |        M1 8-core        |  16 | 1TB |     |  12.2 |   11.0  |    117    |
| MacBook Air 13" 2020 |        M1 8c (8c GPU)   |  16 | 512 |     |  12.2 | 11.0.1  |    128    |
|     Mac mini 2020    |        M1 8-core        |   8 | 256 |     |  12.2 | 11.0.1  |    130    |
| MacBook Air 13" 2020 |        M1 8c (7c GPU)   |   8 | 256 |     |  12.2 | 11.0.1  |    137    |
|     iMac 27" 2019    |    i9 3.6 GHz 8-core    |  64 | 2TB |     |  12.1 | 11.0.1  |    145    |
|     iMac 27" 2020    |    i9 3.6 GHz 10-core   | 128 | 1TB |     |  12.2 | 11.0.1  |    146    |
|   iMac Pro 27" 2017  |   Xeon 3.2 GHz 8-Core   |  32 | 1TB |     |  12.2 | 10.15.7 |    158    |
|     iMac 27" 2019    |    i9 3.6 GHz 8-core    |  40 | 512 |     |  12.2 | 11.0.1  |    163    |
| MacBook Pro 16" 2019 |    i9 2.4 GHz 8-core    |  32 | 512 |     |  12.2 | 11.0.1  |    176    |
|     Mac mini 2018    |    i7 3.2 GHz 6-core    |  32 | 512 |     |  12.2 | 11.0.1  |    192    |
|     iMac 27" 2019    |    i5 3.7 GHz 6-core    |  40 |     | 1TB |  12.3 | 11.0.1  |    195    |
| MacBook Pro 16" 2019 |    i7 2.6 GHz 6-core    |  32 | 1TB |     |  12.3 | 11.1    |    215    |
| MacBook Pro 16" 2019 |    i9 2.3 GHz 8-core    |  32 | 1TB |     |  12.2 | 11.0.1  |    221    |
|     Mac mini 2018    |    i7 3.2 GHz 6-core    |  16 | 1TB |     |  12.0 | 10.15.5 |    228    |
|     iMac 27" 2017    |    i7 4.2 GHz 4-core    |  16 | 1TB |     |  12.2 | 11.0.1  |    246    |
| MacBook Pro 16" 2019 |    i7 2.6 GHz 6-core    |  16 | 512 |     |  12.2 | 11.0.1  |    250    |
| MacBook Pro 13" 2020 |    i5 2.0 GHz 4-core    |  16 | 1TB |     |  12.2 | 11.0.1  |    265    |
| MacBook Pro 15" 2017 |    i7 2.8 GHz 4-core    |  16 | 256 |     |  12.2 | 11.0.1  |    282    |
| MacBook Pro 15" 2015 |    i7 2.2 GHz 4-core    |  16 | 256 |     |  12.1 | 11.0.1  |    324    |
| MacBook Pro 15" 2015 |    i7 2.2 GHz 4-core    |  16 | 256 |     |  12.1 | 10.15.5 |    334    |
| MacBook Pro 15" 2014 |    i7 2.5 GHz 4-core    |  16 | 256 |     |  12.2 | 10.15.7 |    343    |
| MacBook Pro 15" 2013 |    i7 2.3 GHz 4-core    |  16 | 512 |     |  12.2 | 10.15.7 |    374    |
|     iMac 27" 2011    |    i7 3.4 GHz 4-core    |  16 | 250 |     |  12.1 | 10.15.7 |    378    |
| MacBook Pro 13" 2017 |    i5 2.3 GHz 2-core    |  16 | 256 |     |  12.2 | 11.0.1  |    448    |
| MacBook Pro 13" 2016 |    i5 2.9 GHz 2-core    |   8 | 256 |     |  12.2 | 11.0.1  |    518    |
| MacBook Pro 13" 2016 |    i5 2.0 GHz 2-core    |   8 | 256 |     |  12.2 | 11.0.1  |    574    |
| MacBook Pro 13" 2015 |    i5 2.7 Ghz 2-core    |   8 | 512 |     |  12.2 | 10.15.7 |    597    |
| MacBook Air 13" 2015 |    i7 2.2 Ghz 2-core    |   8 | 256 |     |  12.0 | 10.15.7 |    610    |
| MacBook Air 13" 2020 |    i3 1.1 GHz 2-core    |   8 | 256 |     |  12.2 | 11.0.1  |    700    |
|    iMac 21.5" 2017   |    i5 3.0 GHz 4-core    |  16 |     | 1TB |  12.2 | 11.0.1  |    725    |
| MacBook Pro 15" 2012 |    i7 2.7 GHz 4-core    |  16 | 768 |     |  12.4 | 10.15.7 |    785    |
|   MacBook Air 2014   |    i5 1.4 GHz 2-core    |   4 | 128 |     |  12.2 | 11.0.1  |    894    |
|   MacBook Pro 2010   |    i5 2.4 GHz 2-core    |   8 | 480 |     |  12.4 | 10.15.7 |   1043    |


## Xcode 11

|        Device        |           CPU           | RAM | SSD | HDD | Xcode |  macOS  | Time(sec) |
|:--------------------:|:-----------------------:|:---:|:---:|:---:|:-----:|:-------:|:---------:|
|     iMac 27" 2020    |    i9 3.6 GHz 10-core   |  64 | 512 |     |  11.6 | 10.15.6 |    217    |
|   iMac Pro 27" 2017  |  Xeon 3.0 GHz 10-core   |  64 | 1TB |     |  11.7 | 10.15.6 |    222    |
|     iMac 27" 2020    |    i7 3.8 GHz 8-core    |  64 | 512 |     |  11.6 | 10.15.6 |    229    |
|     iMac 27" 2020    |    i7 3.8 GHz 8-core    |  32 | 512 |     |  11.6 | 10.15.6 |    229    |
|     iMac 27" 2019    |    i9 3.6 GHz 8-core    |  64 | 2TB |     |  11.6 | 10.15.6 |    252    |
|   iMac Pro 27" 2017  |   Xeon 3.2 GHz 8-core   |  32 | 1TB |     |  11.6 | 10.15.6 |    263    |
|     Mac Mini 2018    |    i7 3.2 GHz 6-core    |  16 | 512 |     |  11.7 | 10.15.5 |    300    |
| MacBook Pro 16" 2019 |    i9 2.3 GHz 8-core    |  32 | 2TB |     |  11.6 | 10.15.6 |    328    |
| MacBook Pro 16" 2019 |    i7 2.6 GHz 6-core    |  16 | 512 |     |  11.6 | 10.15.6 |    353    |
|     Mac Mini 2018    | i5-8500B 3.0 GHz 6-core |  8  | 512 |     |  11.7 | 10.15.6 |    383    |
|     iMac 27" 2017    |    i7 4.2 GHz 4-core    |  48 | 2TB |     |  11.7 | 10.15.6 |    411    |
|    iMac 21.5" 2017   |  i7-7700 3.6 GHz 4-core |  16 | 1TB |     |  11.7 | 10.16.6 |    419    |
| MacBook Pro 15" 2018 |    i7 2.6 GHz 6-core    |  16 | 512 |     |  11.6 | 10.15.6 |    440    |
|     Mac Pro 2013     |E5-1650 v2 3.5 GHz 6-core|  32 | 1TB |     |  11.7 | 10.15.6 |    518    |
| MacBook Pro 15" 2017 |    i7 2.9 GHz 4-core    |  16 | 512 |     |  11.6 | 10.15.6 |    583    |
| MacBook Pro 15" 2015 |    i7 2.2 GHz 4-core    |  16 | 256 |     |  11.7 | 10.15.6 |    594    |
| MacBook Pro 15" 2016 |    i7 2.7 GHz 4-core    |  16 | 1TB |     |  11.7 | 10.15.6 |    642    |
|     Mac Mini 2014    |    i5 2.6 GHz 2-core    |  8  |     | 1TB |  11.7 | 10.15.6 |    1193   |


## Custom Hardware - Xcode 14
|        Device        |             CPU           | RAM |  SSD  | HDD |  Xcode  |   macOS   | Time(sec) |    Comments    |
|:--------------------:|:-------------------------:|:---:|:-----:|:---:|:-------:|:---------:|:---------:|----------------|
|      Hackintosh      |  i9-13900k 3Ghz 24-core   |  64 | 512GB |     |  14.3.1 |   13.4.1  |    57     |                |
|      Hackintosh      |  i7-8700 3.2 Ghz 6-core   |  16 | 512GB |     |  14.0.1 |    12.6   |    181    | Dell Opt. 3060 |


## Custom Hardware - Xcode 13.3
|        Device        |             CPU           | RAM |  SSD  | HDD |  Xcode  |   macOS   | Time(sec) |    Comments    |
|:--------------------:|:-------------------------:|:---:|:-----:|:---:|:-------:|:---------:|:---------:|----------------|
|      Hackintosh      | i7-12700f 2.1 Ghz 12-core |  32 |  1TB  |     |  13.3   |   12.3    |    98     |                |
|      Hackintosh      | i9-10900k 3.7 Ghz 10-core |  64 | 512GB |     |  13.3   |  12.2.1   |    119    |                |


## Custom Hardware - Xcode 12.5 or above

|        Device        |           CPU           | RAM | SSD | HDD |  Xcode  |  macOS  | Time(sec) |    Comments    |
|:--------------------:|:-----------------------:|:---:|:---:|:---:|:-------:|:-------:|:---------:|----------------|
|      Ryzentosh       | AMD 5950x 4.3 Ghz 16-c  |  32 | 1TB | 2TB |  13.1   |  11.6   |     71    |                |
|      Hackintosh      | i7-9700K 3.6 Ghz 8-core |  16 | 512 | 2TB |  12.5.1 |  11.4   |    177    |                |
|      Hackintosh      | i7-9700  3.0 Ghz 8-core |  32 | 1TB |     |  13.1   |  11.6.1 |    177    |                |


## Custom Hardware - Xcode 12

|        Device        |           CPU           | RAM | SSD | HDD | Xcode |  macOS  | Time(sec) |    Comments    |
|:--------------------:|:-----------------------:|:---:|:---:|:---:|:-----:|:-------:|:---------:|----------------|
|      Hackintosh      |i9-10850K 3.6 Ghz 10-core|  64 | 1TB |     |  12.2 | 10.15.7 |    113    |                |
|      Hackintosh      |i9-10900k 3.7 Ghz 10-core|  64 | 512 | 6TB |  12.2 | 11.0.1  |    122    |                |
|   NLEstation 2020    |    i9 3.6 GHz 8-core    |  64 | 1TB |     |  12.2 | 10.15.7 |    129    |                |
|      Hackintosh      |i7-10700K 3.8 Ghz 8-core |  32 | 1TB |     |  12.2 | 10.15.7 |    130    |                |
|      Hackintosh      |AMD 3800x 4.2 Ghz 8-core |  64 | 1TB |     |  12.2 | 10.15.6 |    137    |                |
|      Hackintosh      | i9-9900K 3.6 Ghz 8-core |  32 | 1TB |     |  12.3 |  11.2   |    157    |                |
|       Ryzentosh      | R9 3900 3.8 Ghz 12-core |  32 | 512 |     |  12.1 | 10.15.4 |    161    |                |
|       Ryzentosh      |  R5 3600 3.6 Ghz 6-core |  16 | 512 |     |  12.3 | 10.15.7 |    175    |                |
|      Hackintosh      |  i5-9400 2.9 Ghz 6-core |  32 | 512 | 2TB |  12.1 | 10.15.7 |    191    |                |
|      Hackintosh      | i3-10100 3.6 Ghz 4-core |  32 | 1TB |     |  12.1 | 10.15.7 |    233    |                |
|      Hackintosh      | i7-4770K 3.5 Ghz 4-core |  16 | 2TB | 8TB |  12.2 | 10.15.7 |    276    |                |
|       QEMU VM        |   Xeon 1.8 Ghz 4-core   |  8  | 32  |     |  12.2 | 10.15.7 |    775    |                |


## Custom Hardware - Xcode 11

|        Device        |           CPU           | RAM | SSD | HDD | Xcode |  macOS  | Time(sec) |    Comments    |
|:--------------------:|:-----------------------:|:---:|:---:|:---:|:-----:|:-------:|:---------:|----------------|
|      Hackintosh      |  i5-8400 2.8 Ghz 6-core |  32 | 512 |     |  11.6 | 10.15.6 |    409    |                |
|       Ryzentosh      |  R5 3600 3.6 Ghz 6-core |  16 | 1TB |     |  11.7 | 10.15.6 |    312    |                |


## Set up

**Since Oct 23, 2021, XcodeBenchmark only supports Xcode 13.0 or above.**

- Download and install [Xcode](https://apps.apple.com/us/app/xcode/id497799835).
- Open Xcode and install `additional tools` (Xcode should suggest it automatically).
- [Download](https://github.com/devMEremenko/XcodeBenchmark/archive/master.zip) and unarchive XcodeBenchmark project.

## Before each test

1. Disconnect the network cable and turn off WiFi.
2. Make sure to disable all software running at startup
    - Go to `System Preferences` -> `Users and Groups` -> `User` -> `Login Items`.
    - Empty the list.
3. Update `Battery` settings 
    - Go to `System Preferences` -> `Battery` -> `Battery/Power Adapter` -> `Turn display off`  and set 15 min.
3. Reboot and cool down your Mac.
4. Connect to the power adapter if you're using a MacBook.

## Running a test

1. Open the `Terminal` app.
2. Write `cd ` and drag & drop `XcodeBenchmark` folder to the `Terminal` app to form `cd path/to/xcode-benchmark`.
2. Run `sh benchmark.sh` in `Terminal`.
3. When `XcodeBenchmark` has completed you will see [this information](img/contribution-example.png).
4. Upload your results, see [Contribution](https://github.com/devMEremenko/XcodeBenchmark#contribution) section.

## FAQ

**Q: What's inside?**

A framework that includes **42** popular CocoaPods libraries and **70+** dependencies in total.

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
1. First of all, the project is **huge**. Most projects are of a much smaller size.
2. The results show *relative* performance in Xcode, compared to other Macs running under similar conditions.

**Q: Why is CocoaPods not excluded from git-repo?**
- The project is also used by non-programmers. Let's *keep it simple*.

**Q: Will it affect my other Xcode projects?**
- A separate build folder is created for the benchmark run that is then deleted after it finishes. The folder goes to about 2.5GB.

## YouTubers and bloggers

You are free to use these results in your videos and articles as well as to run XcodeBenchmark to compare Macs.
Please make sure to add [the link](https://github.com/devMEremenko/XcodeBenchmark/) to this repository.


## Contribution

**Since May 3, 2021, XcodeBenchmark must be used with Xcode 12.5 or above.**

- **If you have any non-Apple hardware components - submit your results to the `Custom Hardware` table.**
- [Submit a pull request](https://github.com/devMEremenko/XcodeBenchmark/pulls).  

Make sure:
- [All steps](https://github.com/devMEremenko/XcodeBenchmark#before-each-test) are performed
- `Time` column is still sorted after insertion.
- Attach a screenshot with a compilation time. [Example](img/contribution-example.png).
- The content in cells is centered.

## Contributors

- [Maxim Eremenko](https://www.linkedin.com/in/maxim-eremenko/)
- [Max Tech](https://www.youtube.com/channel/UCptwuAv0XQHo1OQUSaO6NHw) YouTube channel
- [@bitsmakerde](https://github.com/bitsmakerde)
- [@ivanfeanor](https://github.com/ivanfeanor)
- [@sverrisson](https://github.com/sverrisson)
- [@radianttap](https://github.com/radianttap)
- [@rynaardb](https://github.com/rynaardb)
- [@ekhodykin](https://github.com/ekhodykin)
- [@N0un](https://github.com/N0un)
- [Paul Zabelin](https://github.com/paulz)
- [@theome](https://github.com/Theome)
- [@Kuluum](https://github.com/Kuluum)
- [@villy21](https://github.com/Villy21)
- [@zhi6w](https://github.com/zhi6w)
- [@soorinpark](https://github.com/soorinpark)
- [@igorkulman](https://github.com/igorkulman)
- [@matopeto](https://github.com/matopeto)
- [@morid1n](https://twitter.com/morid1n)
- [@passatgt](https://github.com/passatgt)
- [@ignatovsa](https://github.com/ignatovsa)
- [@azonov](https://github.com/azonov)
- [@euwars](https://twitter.com/euwars)
- [@samadipour](https://github.com/samadipour)
- [@dmcrodrigues](https://github.com/dmcrodrigues)
- [@MeshkaniMohammad](https://github.com/MeshkaniMohammad)
- [@CasperNEw](https://github.com/CasperNEw)
- [@iOSleep](https://github.com/iOSleep)
- [@iPader](https://github.com/ipader)
- [@boltomli](https://github.com/boltomli)
- [@Jimmy-Lee](https://github.com/Jimmy-Lee)
- [@kotalab](https://github.com/kotalab)
- [@valeriyvan](https://github.com/valeriyvan)
- [@twlatl](https://github.com/twlatl)
- [@ypwhs](https://github.com/ypwhs)
- [@freeubi](https://github.com/freeubi)
- [@bariscck](https://github.com/bariscck)
- [@thisura98](https://github.com/Thisura98)
- [@vitallii-t](https://github.com/vitallii-t)
- [@kenji21](https://github.com/kenji21)
- [@hornmichaels](https://github.com/hornmichaels)
- [@sahilsatralkar](https://github.com/sahilsatralkar)
- [@idevid](https://github.com/idevid)
- [@vincentneo](https://github.com/vincentneo)
- [@BradPatras](https://github.com/BradPatras)
- [@LightFocus](https://github.com/lightfocus)
- [@pablosichert](https://github.com/pablosichert)
- [@vm-tester](https://github.com/vm-tester)
- [@rursache](https://github.com/rursache)
- [@wendyliga](https://github.com/wendyliga)
- [@mlch911](https://github.com/mlch911)
- [@apvex](https://github.com/apvex)
- [@Jeehut](https://github.com/Jeehut)
- [@ginamdar](https://github.com/ginamdar)
- [@julianko13](https://github.com/julianko13/)
- [@ispiropoulos](https://github.com/ispiropoulos)
- [@alejedi](https://github.com/alejedi)
- [@witekbobrowski](https://twitter.com/witekbobrowski)
- [@santirodriguezaffonso](https://github.com/santirodriguezaffonso)
- [@alexpereacode](https://github.com/alexpereacode)
- [@fkorotkov](https://github.com/fkorotkov)
