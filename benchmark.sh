readonly PATH_TO_PROJECT=$(pwd)/XcodeBenchmark.xcworkspace

echo ""
echo "Preparing environment"

defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES
#rm -rf ~/Library/Developer/Xcode/DerivedData

if [ -n "$PATH_TO_PROJECT" ]; then 

	echo "Running XcodeBenchmark..."
	echo "Please do not use your Mac while XcodeBenchmark is in progress\n\n"

	xcodebuild -workspace "$PATH_TO_PROJECT" \
			   -scheme XcodeBenchmark \
			   -destination generic/platform=iOS \
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

	echo ""
	echo "✅ XcodeBenchmark is completed"
	echo "1️⃣  Take a screenshot of this window (Cmd + Shift + 4 + Space), it must include:"
	echo "\t- Build Time (See ** BUILD SUCCEEDED ** [XYZ sec])"
	echo "\t- System Version"
	echo "\t- Xcode Version"
	echo "\t- Hardware Overview"
	echo "2️⃣  Share your results at https://github.com/devMEremenko/XcodeBenchmark"
else 
	echo "XcodeBenchmark.xcworkspace was not found in the current folder"
    echo "Are you running in the XcodeBenchmark folder?"
fi
