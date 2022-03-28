readonly PATH_TO_PROJECT=$(pwd)/XcodeBenchmark.xcworkspace
readonly PATH_TO_DERIVED=$(pwd)/DerivedData

clear

echo "Preparing environment"

START_TIME=$(date +"%T")

defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES

if [ -n "$PATH_TO_PROJECT" ]; then 

	echo "Running XcodeBenchmark..."
	echo "Please do not use your Mac while XcodeBenchmark is in progress\n\n"

	xcodebuild -workspace "$PATH_TO_PROJECT" \
			   -scheme XcodeBenchmark \
			   -destination generic/platform=iOS \
			   -derivedDataPath "$PATH_TO_DERIVED" \
			   build

	echo "System Version:" "$(sw_vers -productVersion)"
	xcodebuild -version | grep "Xcode"

	echo "Hardware Overview"
	system_profiler SPHardwareDataType | grep "Model Name:"
	system_profiler SPHardwareDataType | grep "Model Identifier:"

	system_profiler SPHardwareDataType | grep "Processor Name:"
	system_profiler SPHardwareDataType | grep "Processor Speed:"
	system_profiler SPHardwareDataType | grep "Total Number of Cores:"

	system_profiler SPHardwareDataType | grep "L2 Cache (per Core):"
	system_profiler SPHardwareDataType | grep "L3 Cache:"

	system_profiler SPHardwareDataType | grep "Number of Processors:"
	system_profiler SPHardwareDataType | grep "Hyper-Threading Technology:"

	system_profiler SPHardwareDataType | grep "Memory:"
	system_profiler SPSerialATADataType | grep "Model:"

	echo ""
	echo "✅ XcodeBenchmark has completed"
	echo "1️⃣  Take a screenshot of this window (Cmd + Shift + 4 + Space) and resize to include:"
	echo "\t- Build Time (See ** BUILD SUCCEEDED ** [XYZ sec])"
	echo "\t- System Version"
	echo "\t- Xcode Version"
	echo "\t- Hardware Overview"
	
	echo "\t- Started" "$START_TIME"
	echo "\t- Ended  " "$(date +"%T")"
	echo "\t- Date" `date`
	echo ""
	echo "2️⃣  Share your results at https://github.com/devMEremenko/XcodeBenchmark"

	rm -rfd "$PATH_TO_DERIVED"
	
else
    echo "XcodeBenchmark.xcworkspace was not found in the current folder"
    echo "Are you running in the XcodeBenchmark folder?"
fi
