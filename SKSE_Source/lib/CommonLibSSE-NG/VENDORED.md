# Vendored CommonLibSSE (MIT)

Source: https://github.com/MinLL/CommonLibVR (branch `ng`), v4.39.5, commit `550cc4fb9114649dcf526d1f3d73d710c5d7003b`.
OpenVR: https://github.com/ValveSoftware/openvr, commit `60eb187801956ad277f1cae6680e3a410ee0873b`, in `extern/openvr`.

Same pin as SkyrimNet_SexLab `SKSE_Source/lib/CommonLibSSE-NG` (and its `extern/vcpkg-ports/commonlibsse-ng-fork`).
Replaces the alandtse/CommonLibVR 4.39.2 vcpkg overlay port. This tree is MIT (see `LICENSE`).

Taken from the GitHub archives (SHA512 `a053d852…` / `bb85b470…`, as in SexLab's portfile), with these local changes:

- Upstream `.gitignore` (ignores `*.cmake`) and `.gitmodules` removed, so `cmake/*.cmake` stays tracked.
- OpenVR trimmed to what the build uses: `headers/`, `lib/win64/`, `LICENSE`, `README.md`.

To bump: re-extract the new MinLL archive over this folder, re-apply the two changes above, and update this file.
