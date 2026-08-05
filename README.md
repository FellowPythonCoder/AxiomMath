
# AxiomMath
Math learning app
Please download the zip file the Hi folder doesnt work :)
## Getting Started

Download ZIP this repo. Create a folder called `Axiom`, and inside it:


See video below for a visual guide.

# Axiom

## What is Axiom?

Axiom is a math learning app for the iPhone. It is made for kids and students who want to get better at math in a fun way, kind of like a game. Instead of just doing boring worksheets, you answer math questions, earn coins and XP (experience points), buy cute pets and themes with your coins, and climb up a leaderboard to see how you compare to other people.

### The problem it solves

A lot of math practice apps are either:
- Too boring (just plain question after question with no reward), or
- Not actually teaching anything (they just tell you if you got it wrong and move on)

Axiom tries to fix both of those problems:
1. **It's fun.** You get coins, XP, a mascot buddy, pets, and a daily challenge with a big reward. This makes practicing math feel more like playing a game.
2. **It actually teaches.** If you get a question wrong, Axiom doesn't just say "nope, wrong answer." It shows you a whiteboard pop-up that walks you through the steps to solve it, like a tutor would. It even reads the question out loud using AI voice (ElevenLabs), so it feels like a real person is teaching you.
3. **It grows with you.** Questions get harder or easier depending on your grade level, from simple counting all the way up to quadratic equations.

### How it works (the big picture)

Axiom has two main parts that talk to each other:

1. **The iPhone App (Frontend)** — built with Swift and SwiftUI. This is the part you actually see and tap on: the home screen, the shop, the quiz screens, the mascot character, and the whiteboard teaching pop-up.

2. **The Server (Backend)** — built with Python (using a tool called Flask). This is the "brain" that lives on a computer. It:
   - Creates new math questions for you to answer
   - Remembers your account (name, email, password)
   - Keeps track of your XP, coins, and points in a database
   - Sends the leaderboard back to the app
   - Uses a small C program (compiled into a `.dylib` file) to generate math questions super fast

So basically: **the app asks the server for a question → the server makes one (using either Python or the fast C code) → the app shows it to you → you answer → the app tells the server if you got it right → the server updates your coins and XP → you see them go up on your screen.**

The app and the server talk to each other over the internet (or your Wi-Fi network) using something called an API — think of it like the app "calling" the server and asking "hey, give me 5 questions for grade 4" and the server calling back with the answer.

---

## What's in the project folder

| File | What it does |
|---|---|
| `AxiomApp.swift` | The starting point of the app. Also stores all your app's data while it's running (login info, coins, XP, etc.) |
| `ContentView.swift` | The main screen layout |
| `ApiClient.swift` | Handles sending requests to the Python server (login, signup, getting questions, etc.) |
| `Models.swift` | Defines the "shapes" of data, like what a Question or a User Profile looks like |
| `TeachingEngine.swift` | Figures out how to explain a math question step-by-step when you get it wrong |
| `WhiteboardTeachOverlay.swift` | The animated whiteboard pop-up screen that shows the step-by-step teaching |
| `Mascot.swift` | The cartoon buddy character that reacts with different faces (happy, thinking, oops) |
| `ElevenLabsManager.swift` | Makes the app talk out loud using AI voice |
| `LoadingAnimationView.swift` | The animated loading screen you see when the app starts |
| `Theme.swift` | All the colors and styles used across the app |
| `main.py` | The Python server — this is what runs on your computer and handles all requests from the app |
| `lesson_generator.py` | Python code that creates math questions |
| `math_engine.c` / `generator.c` | C code that creates math questions super fast |
| `libmathengine.dylib` | The compiled version of the C code that Python actually uses |
| `schema.sql` | Describes how the database is organized (tables for users, owned items, etc.) |
| `queries.sql` | Example database queries |
| `requirements.txt` | A list of Python tools (packages) the server needs to run |
| `Info.plist` | Settings for the iPhone app (like permissions) |
| `Assets.xcassets` | Images and icons used in the app |

---

## Setup Guide (step-by-step)

This guide will help you get Axiom running, even if you've never done this before. Take it slow, one step at a time. It's normal to run into a hiccup — the "Common Problems" section near the end covers the usual ones.

### Part 0: What you need before starting

You will need **a Mac computer**. This is required because building iPhone apps only works on a Mac. You cannot do this on Windows or Chromebook.

Here's what to download:

1. **Xcode** — this is the program that lets you build and run the iPhone app.
   - Open the **App Store** app on your Mac
   - Search "Xcode"
   - Click **Get** / **Install** (it's free, but it's a big download — could take a while, so be patient)

2. **Python 3** — this runs the server.
   - Go to [python.org/downloads](https://www.python.org/downloads/)
   - Download the newest version for macOS
   - Open the downloaded file and click through the installer

(You do not need a separate code editor like VS Code — Xcode and Terminal are enough.)

---

### Part 1: Setting up the folders

1. Download both folders from this repo.
2. Create a folder on your Desktop (or wherever you like) called `Axiom`.
3. Inside it, place the folder that has all the `.swift` files, `Assets.xcassets`, and `Info.plist` — **rename this folder from `Hi` to `Frontend`.**
4. Also place the `Backend` folder (with `main.py`, `lesson_generator.py`, `schema.sql`, `queries.sql`, `requirements.txt`, `math_engine.c`, `generator.c`, `libmathengine.dylib`) next to it.

Your folder structure should look like this:
Axiom/
├── Frontend/
│ └── Axiom/ (this is the Xcode project — .swift files, Assets.xcassets, Info.plist)
└── Backend/
├── main.py
├── lesson_generator.py
├── math_engine.c
├── generator.c
├── libmathengine.dylib
├── schema.sql
├── queries.sql
└── requirements.txt

> ⚠️ **Important:** The `libmathengine.dylib` file needs to be in the **same folder** as `main.py`. The server looks for it right next to itself. If it's in a different folder, the server will silently fall back to Python-only questions.

---

### Part 2: Setting up the Backend (the server)

1. Open the **Terminal** app on your Mac (press `Cmd + Space`, type "Terminal").

2. Move into your Backend folder. Type `cd ` (with a space after it), then drag the Backend folder into the Terminal window, and press Enter:
cd /Users/YourName/Desktop/Axiom/Backend

3. Create a virtual environment (keeps this project's Python tools separate from everything else):
python3 -m venv venv
source venv/bin/activate
   You'll know it worked if you see `(venv)` at the start of your Terminal line.

4. Install the required Python tools:
pip install -r requirements.txt

5. **Rebuild the `.dylib` file (recommended).** Mac security often blocks binaries built on a different Mac, so rebuild it yourself:
clang -shared -fPIC -o libmathengine.dylib math_engine.c generator.c

6. Start the server:
python3 main.py
   You should see something like `Running on http://0.0.0.0:5000`. **Leave this Terminal window open** — closing it stops the server.

7. The first run automatically creates `axiom.db` using `schema.sql`. Nothing extra needed.

---

### Part 3: Setting up the Frontend (the iPhone app)

1. Open Xcode.

2. **File → Open**, and select the `Frontend/Axiom` folder (or the `.xcodeproj` file inside it).

3. Find your computer's IP address:
   - Apple menu → **System Settings** → **Wi-Fi** → click the "i"/Details next to your network
   - Look for "IP Address" — something like `192.168.x.x` or `10.0.0.x`

4. Open `ApiClient.swift` and find:
```swift
let SERVER_BASE_URL = "http://10.0.0.54:5000"
```
   Replace `10.0.0.54` with **your own Mac's IP address**. Keep `:5000`.

5. (Optional) For AI voice: get a free API key from [elevenlabs.io](https://elevenlabs.io/), then in `Info.plist` add a new row named `ElevenLabsAPIKey` with your key as the value. If you skip this, the app just uses the iPhone's built-in voice instead.

6. Since the server uses `http://` (not `https://`), you need to allow this in `Info.plist` via an App Transport Security exception (Allow Arbitrary Loads, or an exception for your local IP), or the app will fail to connect.

---

### Part 4: Running the app

#### Option A: Simulator (easiest)
1. Make sure the Python server is still running.
2. In Xcode, pick any iPhone simulator from the device dropdown.
3. Press the ▶️ Play button (or `Cmd + R`).
4. The simulator opens and the app launches automatically.

#### Option B: Real iPhone
1. Plug in your iPhone, tap **Trust** if prompted.
2. Select your iPhone in Xcode's device dropdown.
3. Press ▶️ Play.
4. If asked for a developer account: Xcode → **Settings → Accounts** → sign in with your Apple ID → back in your project settings → **Signing & Capabilities** → choose your name under "Team."
5. On the iPhone, you may need **Settings → General → VPN & Device Management** to trust your developer profile.
6. **Your iPhone and Mac must be on the same Wi-Fi network.**

---

## Common Problems (and how to fix them)

**"Could not connect to the server" / app spins or shows a network error**
- Make sure `main.py` is still running in Terminal.
- Double-check the IP address in `ApiClient.swift` matches your current Mac IP (it can change after Wi-Fi restarts).
- Confirm your iPhone/simulator and Mac are on the same Wi-Fi network.

**"App Transport Security" error, or requests silently fail**
- Add the ATS exception in `Info.plist` (Part 3, step 6).

**The `.dylib` won't load / "image not found" error**
- Rebuild it with the `clang` command in Part 2, step 5 — pre-built binaries often don't match a different Mac/chip.

**"No module named flask" error**
- Activate your virtual environment first: `source venv/bin/activate`, then `python3 main.py`.

**Xcode says "Signing for Axiom requires a development team"**
- Sign in with your Apple ID under Xcode → Settings → Accounts, then set your Team under Signing & Capabilities.

**Simulator works but real iPhone doesn't**
- Almost always the Wi-Fi network or trust/signing steps in Part 4, Option B.

**AI voice doesn't play, uses a regular voice instead**
- Normal if you skipped the ElevenLabs API key, or it ran out of free credits. The app automatically falls back to the iPhone's built-in voice.

**Leaderboard or coins don't update**
- Make sure only one `python3 main.py` is running — extra leftover servers can cause weirdness.

---

## Quick Recap Checklist

- [ ] Downloaded Xcode
- [ ] Downloaded Python 3
- [ ] Renamed `Hi` folder to `Frontend`
- [ ] Backend folder has `main.py` and `libmathengine.dylib` together
- [ ] Ran `pip install -r requirements.txt`
- [ ] Rebuilt the `.dylib` with `clang`
- [ ] Server running (`python3 main.py`) and left open
- [ ] Updated `SERVER_BASE_URL` in `ApiClient.swift` with your Mac's IP
- [ ] Added App Transport Security exception in `Info.plist`
- [ ] (Optional) Added ElevenLabs API key
- [ ] Same Wi-Fi network for phone + Mac
- [ ] Signed the app with your Apple ID in Xcode (for real device)

That's it — you should now have Axiom up and running! 🎉
