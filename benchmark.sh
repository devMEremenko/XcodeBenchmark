# Prepare running
echo ""
echo "Running XcodeBenchmark"
echo "Preparing environment"
defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES
rm -rf ~/Library/Developer/Xcode/DerivedData

echo "Xcode Version: "
echo $(xed -v)

# Open Xcode
echo "Open Xcode: "
xcodeBenchmark=$(ls -d XcodeBenchmark.xcworkspace/ 2>/dev/null)
if [ -n "$xcodeBenchmark" ]; then 
    echo $xcodeBenchmark
    (time xcodebuild -workspace "$xcodeBenchmark" -scheme XcodeBenchmark build -quiet > /dev/null)
    echo $(xed -v)
    system_profiler -detailLevel mini SPHardwareDataType
else
    echo "No xcworkspace - Are you running in the XcodeBenchmark folder?"
fi