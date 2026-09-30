# License scope and third-party notices

New skill instructions, documentation and packaging contributions: MIT, see root `LICENSE`.
Bridge source and app: MIT; preserve `MiRemoteVoice-MIT.txt`, `mi-ao-MIT.txt` and `ATVVoice-MIT.txt` for their respective upstream contributions. Direct base: [VincentKingHsu/MiRemoteVoice](https://github.com/VincentKingHsu/MiRemoteVoice), local customized snapshot dated 2026-09-25. The exact source for the supplied candidate app is under `source/bridge`.
Driver source, driver binary and PKG: GNU GPL v3, **not covered by the root MIT license**; corresponding source and build inputs are under `source/driver`, full license in `BlackHole-GPL-3.0.txt`. No claim is made that independently rebuilt binaries are byte-for-byte identical across SDK/compiler versions.
Doubao IME, Codex and Xiaomi hardware are separate products, not redistributed under this license.

`mi-remote-bridge` contains code adapted from
[fanxeon/mi-ao](https://github.com/fanxeon/mi-ao), distributed under the MIT
License, Copyright (c) 2026 FanXeon@Poemcoder with Codex.

Its ATVV protocol and IMA/DVI ADPCM implementation were informed by:

- [b0o/ATVVoice](https://github.com/b0o/ATVVoice), MIT License,
  Copyright (c) 2026 Maddison Cohodas.
- [Google Voice over BLE specification v1.0](https://wangefan.github.io/linux_kernel_driver/resources/Google_Voice_over_BLE_spec_v1.0.pdf).

`MiRemoteVoice.driver` is a modified build of
[ExistentialAudio/BlackHole](https://github.com/ExistentialAudio/BlackHole)
0.4.1 and remains licensed under GNU GPL v3. The corresponding modified source and build inputs are included in
source/driver. Its GPL v3 license is provided in licenses/BlackHole-GPL-3.0.txt.
The device name, bundle identifier, factory UUID and device transport were
changed; the audio core remains based on upstream BlackHole 0.4.1.

