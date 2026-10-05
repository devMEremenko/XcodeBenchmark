#!/bin/sh

readonly PATH_TO_PROJECT="$(pwd)/XcodeBenchmark.xcworkspace" # Locate the benchmark workspace.

if [ ! -d "$PATH_TO_PROJECT" ]; then # Require the workspace before changing build data.
    echo "XcodeBenchmark.xcworkspace was not found in the current folder" # Explain the missing workspace.
    echo "Are you running in the XcodeBenchmark folder?" # Suggest the expected working directory.
    exit 1 # Stop without a benchmark result.
fi # Finish workspace validation.

RUN_DIRECTORY=$(mktemp -d "$(pwd)/.xcodebenchmark.XXXXXX") || exit 1 # Isolate each run on the checkout's disk.
readonly PATH_TO_DERIVED="$RUN_DIRECTORY/DerivedData" # Keep fresh build products inside this run's directory.
CAPTURE_PID= # Start without an output-capture process to clean up.
cleanup() { # Remove only benchmark data and temporary output.
    if [ -n "$CAPTURE_PID" ]; then # Stop output capture if it has not already been reaped.
        kill -TERM "$CAPTURE_PID" 2>/dev/null # Request termination, ignoring an already-exited process.
        wait "$CAPTURE_PID" 2>/dev/null # Reap the capture process before removing its files.
    fi # Finish output-capture cleanup.
    rm -rf "$RUN_DIRECTORY" # Delete only this run's build products and output.
} # Finish the cleanup helper.
trap cleanup EXIT # Clean up when the script exits.
trap 'exit 130' INT # Let the terminal deliver SIGINT directly to the foreground build.
trap 'exit 143' TERM HUP # Clean up after the foreground command returns.

if [ -t 1 ]; then # Clear only an interactive terminal.
    clear # Make the benchmark output easier to see.
fi # Finish terminal preparation.
echo "Preparing environment" # Announce benchmark preparation.
START_TIME=$(date +"%T") # Record the start time.
SOURCE_REVISION=$(git rev-parse HEAD 2>/dev/null) # Record the benchmark source revision.

if ! defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES >/dev/null 2>&1; then # Enable Xcode's build duration output.
    echo "Warning: failed to enable Xcode build duration output" # Explain why a duration might be missing.
fi # Finish duration setup.

echo "Running XcodeBenchmark..." # Announce the build.
printf 'Please do not use your Mac while XcodeBenchmark is in progress\n\n' # Ask the user to avoid competing work.
mkfifo "$RUN_DIRECTORY/output" || exit 1 # Capture output without moving the build into the background.
tee "$RUN_DIRECTORY/build.log" < "$RUN_DIRECTORY/output" & # Display and save build output in a background reader.
CAPTURE_PID=$! # Record the reader's process ID for waiting and cleanup.
xcodebuild -workspace "$PATH_TO_PROJECT" -scheme XcodeBenchmark -destination generic/platform=iOS -derivedDataPath "$PATH_TO_DERIVED" build > "$RUN_DIRECTORY/output" 2>&1 # Build in the terminal's foreground process group.
BUILD_STATUS=$? # Preserve the foreground build's exit status.
wait "$CAPTURE_PID" # Wait until the reader has consumed the complete build output.
CAPTURE_STATUS=$? # Preserve the output reader's exit status.
CAPTURE_PID= # Mark the reader as reaped so cleanup does not signal it again.
if [ "$CAPTURE_STATUS" -ne 0 ] || [ "$BUILD_STATUS" -ne 0 ]; then # Require successful building and output capture.
    echo "❌ XcodeBenchmark build failed" # Report the failed benchmark.
    exit 1 # Stop without a benchmark result.
fi # Finish build validation.

DURATION=$(LC_ALL=C awk ' # Read the Xcode duration from the captured output.
    /^\*\* BUILD SUCCEEDED \*\* \[[0-9]+([.][0-9]+)? sec\][[:space:]]*$/ { # Match a successful build with a duration.
        sub(/^.*\[/, "") # Remove the text before the duration.
        sub(/ sec\].*$/, "") # Remove the units and closing bracket.
        duration = $0 # Preserve the original duration.
        count++ # Count matching duration lines.
    } # Finish processing a matching line.
    END { # Validate the complete captured output.
        if (count != 1 || duration <= 0) exit 1 # Reject missing, duplicate, or invalid durations.
        print duration # Print the validated duration.
    } # Finish duration validation.
' "$RUN_DIRECTORY/build.log") # Extract the build duration.
if [ "$?" -ne 0 ]; then # Require a valid duration before reporting a result.
    echo "❌ XcodeBenchmark has no single valid Xcode build duration" # Explain why the output cannot be submitted.
    exit 1 # Stop without a benchmark result.
fi # Finish duration extraction.
README_TIME=$(LC_ALL=C awk -v duration="$DURATION" 'BEGIN { printf "%d", int(duration + 0.5) }') # Round the duration to whole seconds for the README.

echo "" # Separate the summary from build output.
echo "Benchmark revision: ${SOURCE_REVISION:-unavailable}" # Identify the measured source revision.
echo "Repository: https://github.com/devMEremenko/XcodeBenchmark" # Link to the result repository.
if ! sh ./scripts/system-info.sh; then # Collect the device and software details.
    echo "Warning: system information collection failed; verify missing details before submission" # Identify incomplete metadata while keeping the valid duration.
fi # Finish system information collection.
echo "" # Separate completion details from the result.
echo "✅ XcodeBenchmark has completed" # Announce successful benchmark completion.
echo "Build Time: $README_TIME sec ($DURATION sec)" # Show the rounded README value and original Xcode measurement.
printf 'Started: %s\nEnded:   %s\nDate:    %s\n' "$START_TIME" "$(date +"%T")" "$(date)" # Print the benchmark's timestamps.
echo "Share your results at https://github.com/devMEremenko/XcodeBenchmark" # Explain where results can be submitted.
