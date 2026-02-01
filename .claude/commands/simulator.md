Launch FitPulse on iOS Simulator.

Steps:
1. Boot the simulator: `xcrun simctl boot "iPhone 16 Pro"`
2. Install the app: `xcrun simctl install booted build/Debug-iphonesimulator/FitPulse.app`
3. Launch the app: `xcrun simctl launch booted com.fitpulse.app`

If the app hasn't been built yet, run /build first.
