# BayanGold — Alternate iOS App Icon

Place the gold icon PNG files directly in this folder (`ios/Runner/BayanGold/`).

## Required files

| File                  | Size     | Usage              |
|-----------------------|----------|--------------------|
| `BayanGold@2x.png`    | 120×120  | iPhone (2× Retina) |
| `BayanGold@3x.png`    | 180×180  | iPhone (3× Retina) |

## Notes
- Icons must be **square**, no rounded corners (iOS clips them automatically).
- No transparency / alpha channel.
- The file name prefix (`BayanGold`) must match the key in `CFBundleAlternateIcons`
  inside `Info.plist` and the `iosIconName` on `AppIconVariant.gold`.
- After placing the files, add them to the Xcode project under the Runner target
  (drag into Xcode, ensure "Copy items if needed" is checked, target = Runner).
