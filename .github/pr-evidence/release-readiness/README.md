# Release readiness evidence

`merit-state-regression.png` is an authentic QtQuick offscreen render of
[`tests/merit-state-regression.qml`](../../../tests/merit-state-regression.qml).
The fixture loads the production [`MeritState.qml`](../../../MeritState.qml)
and exercises snapshots both during a pending tap and after its acknowledgement,
two serialized rapid-knock replies, malformed-response rollback, midnight
rollover, and an external-client refresh. It also renders the explicit 4% and
12% alpha overlays used with `Qt.tint` in the panel. The production
[`ProcessResultGate.qml`](../../../ProcessResultGate.qml) is exercised with
both signal orders, an attempted new batch between the two signals, and the
failed-to-start path. Process exit codes are accepted only for `NormalExit`;
`CrashExit` is passed to the gate as a failure.

Recreate it from the repository root with:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /usr/lib/qt6/bin/qml tests/merit-state-regression.qml
```

This is a test fixture image, not a screenshot of the full plugin or an Omarchy
desktop. It uses the production counter state object but does not launch
Quickshell, access user configuration or merit data, or exercise theme-specific
contrast on a live panel. The full widget is checked separately with the
installed Omarchy QML imports and `qmllint`. The harness accepts
`-- --force-failure` as a negative control to verify a failed assertion exits
nonzero; that run intentionally overwrites the screenshot with a failure image,
so rerun the normal command to restore the passing evidence.
