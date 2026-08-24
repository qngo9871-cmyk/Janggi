#!/usr/bin/env python3
"""Capture REAL in-app App Store screenshots for Janggi (Korean Chess) via the
simulator and DEBUG JG_CAPTURE launch args (home|board|opening|select|midgame).
Adds a Han/Cho (red-to-blue) caption band. Every shot is the actual app UI
(App Review 2.3.3); no prices (DEBUG forces isPro so no lock/upgrade prompts).
Output: screenshots/v2/*.png"""
import os, re, subprocess, time
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

APP_DIR = Path(__file__).resolve().parent
PROJECT = APP_DIR / "Janggi.xcodeproj"
SCHEME = "Janggi"
BUNDLE = "com.quyenngo.janggi"
OUT = APP_DIR / "screenshots" / "v2"; OUT.mkdir(parents=True, exist_ok=True)
W, H = 1320, 2868
BAND = 470

SHOTS = [
    ("01-home",    "home",    "Play authentic Janggi\nwith a sharp AI"),
    ("02-board",   "board",   "The real 9×10 board —\npalace diagonals"),
    ("03-opening", "opening", "All seven pieces:\ncannon, horse, chariot"),
    ("04-select",  "select",  "Tap a piece, see\nevery legal move"),
    ("05-midgame", "midgame", "Solo vs AI or\npass-and-play a friend"),
]


def sh(*a, **k): return subprocess.run(a, check=True, capture_output=True, text=True, **k)


DEDICATED_DEVICE_NAME = "Janggi-Capture"


def find_device():
    # Use a dedicated, app-named simulator device rather than a generic shared
    # name — running this alongside other apps' concurrent capture scripts on a
    # shared simulator has previously captured a DIFFERENT app's UI by mistake.
    out = subprocess.run(["xcrun", "simctl", "list", "devices", "available"],
                         capture_output=True, text=True).stdout
    for line in out.splitlines():
        m = re.search(rf"^\s*{re.escape(DEDICATED_DEVICE_NAME)}\s+\(([0-9A-F\-]{{36}})\)", line)
        if m:
            return m.group(1), DEDICATED_DEVICE_NAME
    # Not created yet — create it against a modern iPhone Pro Max device type.
    devtypes = subprocess.run(["xcrun", "simctl", "list", "devicetypes"],
                              capture_output=True, text=True).stdout
    dt = None
    for line in devtypes.splitlines():
        m = re.search(r"^\s*(iPhone .*Pro Max)\s+\(", line)
        if m:
            dt = m.group(1)
    if not dt:
        raise SystemExit("No 'iPhone ... Pro Max' device type found to create the dedicated simulator")
    udid = sh("xcrun", "simctl", "create", DEDICATED_DEVICE_NAME, dt).stdout.strip()
    return udid, DEDICATED_DEVICE_NAME


def build_app():
    sh("xcodebuild", "-project", str(PROJECT), "-scheme", SCHEME, "-configuration", "Debug",
       "-sdk", "iphonesimulator", "-derivedDataPath", str(APP_DIR / "build/sim"), "build",
       cwd=str(APP_DIR))
    app = APP_DIR / "build/sim/Build/Products/Debug-iphonesimulator/Janggi.app"
    if not app.exists():
        raise SystemExit(f"built app not found at {app}")
    return app


def font(size):
    for c in ["/System/Library/Fonts/SFNSDisplay.ttf", "/System/Library/Fonts/SFNS.ttf",
              "/System/Library/Fonts/Supplemental/Arial Bold.ttf"]:
        if Path(c).exists():
            try: return ImageFont.truetype(c, size)
            except Exception: continue
    return ImageFont.load_default()


def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def compose(raw_png, headline, out_png):
    shot = Image.open(raw_png).convert("RGB").resize((W, H), Image.LANCZOS)
    canvas = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(canvas)
    top, bot = (168, 42, 34), (30, 60, 130)   # Han red -> Cho blue
    for y in range(H):
        d.line([(0, y), (W, y)], fill=lerp(top, bot, y / H))
    f = font(112)
    lines = headline.split("\n"); lh = 128
    y = (BAND - lh * len(lines)) // 2 + 8
    for line in lines:
        w = d.textlength(line, font=f)
        d.text(((W - w) / 2, y), line, font=f, fill=(250, 240, 224)); y += lh
    avail_h = H - BAND - 70
    sw = int(W * 0.84); sh_ = int(shot.height * sw / shot.width)
    if sh_ > avail_h: sh_ = avail_h; sw = int(shot.width * sh_ / shot.height)
    shot = shot.resize((sw, sh_), Image.LANCZOS)
    mask = Image.new("L", (sw, sh_), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh_], radius=54, fill=255)
    px = (W - sw) // 2; py = BAND + (avail_h - sh_) // 2 + 35
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([px, py + 16, px + sw, py + sh_ + 16], radius=54, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB")
    canvas.paste(shot, (px, py), mask)
    canvas.save(out_png); print(f"  wrote {out_png.name}")


def main():
    DEVICE, name = find_device()
    print(f"==> device {name}")
    APP = build_app()
    subprocess.run(["xcrun", "simctl", "shutdown", DEVICE], capture_output=True)
    subprocess.run(["xcrun", "simctl", "erase", DEVICE], capture_output=True)
    subprocess.run(["xcrun", "simctl", "boot", DEVICE], capture_output=True)
    sh("xcrun", "simctl", "bootstatus", DEVICE, "-b")
    subprocess.run(["xcrun", "simctl", "status_bar", DEVICE, "override", "--time", "9:41",
                    "--batteryLevel", "100", "--batteryState", "charged",
                    "--cellularBars", "4", "--wifiBars", "3"], capture_output=True)
    sh("xcrun", "simctl", "install", DEVICE, str(APP))
    # A freshly-erased simulator can surface a first-boot system notification
    # banner ("Ready for Apple Intelligence") a few seconds in, which then
    # auto-dismisses on its own — wait it out before capturing so it doesn't
    # land in a screenshot (found via vision QA, 2026-08-24).
    time.sleep(8)
    raw = OUT / "_raw.png"
    for shotname, cap, headline in SHOTS:
        subprocess.run(["xcrun", "simctl", "terminate", DEVICE, BUNDLE], capture_output=True)
        subprocess.run(["xcrun", "simctl", "launch", DEVICE, BUNDLE],
                       env=dict(os.environ, SIMCTL_CHILD_JG_CAPTURE=cap), capture_output=True)
        time.sleep(5)
        sh("xcrun", "simctl", "io", DEVICE, "screenshot", str(raw))
        compose(raw, headline, OUT / f"{shotname}.png")
    raw.unlink(missing_ok=True)
    subprocess.run(["xcrun", "simctl", "terminate", DEVICE, BUNDLE], capture_output=True)
    print("==> done.", OUT)


if __name__ == "__main__":
    main()
