// App-wide flags shared between screens without circular imports.

/// Set to true by SplashScreen right after its pushReplacement completes.
/// Widget-triggered navigation (Add Expense / Income) waits for this flag
/// so it doesn't get stomped by splash's own route replacement.
bool splashNavigationDone = false;
