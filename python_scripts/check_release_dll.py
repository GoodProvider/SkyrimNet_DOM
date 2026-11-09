"""Fail if the SKSE plugin about to be released links the Debug C++ runtime.

Debug runtime DLLs exist only on machines with Visual Studio, so a Debug plugin
fails to load everywhere else with Error 126.
"""
import sys
from pathlib import Path

DEFAULT_DLL = Path("SKSE/Plugins/SkyrimNet_DOM.dll")
DEBUG_RUNTIMES = (
    b"msvcp140d.dll",
    b"vcruntime140d.dll",
    b"vcruntime140_1d.dll",
    b"ucrtbased.dll",
)


def main() -> int:
    dll = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_DLL
    if not dll.is_file():
        print(f"ERROR: {dll} not found", file=sys.stderr)
        return 1

    content = dll.read_bytes().lower()
    found = [name.decode() for name in DEBUG_RUNTIMES if name in content]
    if found:
        print(f"ERROR: {dll} is a Debug build; it needs {', '.join(found)}", file=sys.stderr)
        print("Rebuild it from SKSE_Source with CMake --preset release.", file=sys.stderr)
        return 1

    print(f"OK: {dll} does not link the Debug C++ runtime")
    return 0


if __name__ == "__main__":
    sys.exit(main())
