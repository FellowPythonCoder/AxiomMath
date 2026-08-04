# AxiomMath
Math learning app

Download Both folders
Create a Folder Called Axiom then change Hi folder name to Frontend

See Video
below for visual guide
 Axiom 

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

3. **A code editor for the Python side (optional)** — something like **Visual Studio Code** (free, download from [code.visualstudio.com](https://code.visualstudio.com/)). You technically could use Xcode for everything, but VS Code makes editing Python files easier.  (THIS NOT NOT NEEDED)

---

### Part 1: Setting up the folders

1. Save the whole project folder somewhere easy to find, like your Desktop or Documents. Keep the **Frontend** files (the `.swift` files, `Assets.xcassets`, `Info.plist`) together, and the **Backend** files (`main.py`, `lesson_generator.py`, `schema.sql`, `queries.sql`, `requirements.txt`, `math_engine.c`, `generator.c`, `libmathengine.dylib`) together in a separate folder.

2. Your folder structure should look something like this:
```
Axiom/
├── Hi/
│   └── Axiom/  (this is the Xcode project — .swift files, Assets.xcassets, Info.plist)
└── Backend/
    ├── main.py
    ├── lesson_generator.py
    ├── math_engine.c
    ├── generator.c
    ├── libmathengine.dylib
    ├── schema.sql
    ├── queries.sql
    └── requirements.txt
```



---

### Part 2: Setting up the Backend (the server)

1. Open the **Terminal** app on your Mac (search for it with Spotlight — press `Cmd + Space` and type "Terminal").

2. Move into your Backend folder. Type `cd ` (with a space after it) then drag the Backend folder into the Terminal window, then press Enter. It should look something like:
```
cd /Users/YourName/Desktop/Axiom/Backend
```

3. Create a "virtual environment" — this just keeps all the Python tools for this project separate from everything else on your computer, so nothing gets messy. Type:
```
python3 -m venv venv
source venv/bin/activate
```
   You'll know it worked if you see `(venv)` appear at the start of your Terminal line.

4. Install the required Python tools by typing:
```
pip install -r requirements.txt
```
   This installs Flask (the web server tool) and Flask-Cors (which lets the app talk to the server).

5. **Rebuild the `.dylib` file (recommended).** The one included in the project was built on someone else's Mac, and Mac security sometimes blocks files built on other computers. It's safer to rebuild it yourself. In Terminal, still inside the Backend folder, type:
```
clang -shared -fPIC -o libmathengine.dylib math_engine.c generator.c
```
   This creates a fresh `libmathengine.dylib` that matches your computer.

6. Start the server by typing:
```
python3 main.py
```
   If it worked, you'll see some text in Terminal saying something like `Running on http://0.0.0.0:5000`. **Leave this Terminal window open** — closing it turns the server off.

7. The very first time you run it, it will automatically create a database file called `axiom.db` using the layout described in `schema.sql`. You don't need to do anything extra for this.

---

### Part 3: Setting up the Frontend (the iPhone app)

1. Open Xcode.

2. Open your project by going to **File → Open**, and selecting the `Frontend/Axiom` folder (or the `.xcodeproj` file inside it, if you have one).

3. **Find your computer's IP address** (this is important, so the app knows where to find your server):
   - Click the Apple menu (top left) → **System Settings** → **Wi-Fi** → click the little "i" or "Details" button next to your connected network
   - Look for something called "IP Address" — it will look like `192.168.x.x` or `10.0.0.x`

4. Open `ApiClient.swift` in Xcode and find this line near the top:
```swift
let SERVER_BASE_URL = "http://10.0.0.54:5000"
```
   Change `10.0.0.54` to **your own computer's IP address** that you found in step 3. Keep the `:5000` part the same (that matches the port your Python server runs on).

5. In `ElevenLabsManager.swift`, the app looks for an ElevenLabs API key (this is what makes the AI voice work) inside `Info.plist` under a key called `ElevenLabsAPIKey`. If you want the AI voice feature:
   - Go to [elevenlabs.io](https://elevenlabs.io/) and make a free account
   - Get your API key from your account settings
   - Open `Info.plist` in Xcode, add a new row, name it `ElevenLabsAPIKey`, and paste your key in as the value

   If you skip this step, don't worry — the app will still talk, just using the iPhone's regular built-in voice instead of the fancier AI one.

6. Because the server uses `http://` and not the more secure `https://`, iPhones normally block this for safety. You need to allow it for local testing. In `Info.plist`, make sure there's an entry that allows insecure local networking (usually called **App Transport Security Settings → Allow Arbitrary Loads**, or specifically allowing your local IP). If this isn't there yet, add it, or Xcode/your app may show connection errors.

---

### Part 4: Running the app

You have two choices: the **Simulator** (a fake iPhone on your Mac screen) or a **real iPhone**.

#### Option A: Running on the Simulator (easiest)
1. Make sure your Python server is still running in Terminal (Part 2, step 6).
2. In Xcode, at the top of the window, click the device dropdown and choose any iPhone simulator (like "iPhone 15").
3. Click the  **Play** button (or press `Cmd + R`).
4. Wait for it to build — the simulator will pop up automatically and the app should launch.

#### Option B: Running on your real iPhone
1. Plug your iPhone into your Mac with a cable (or set up wireless debugging in Xcode, but a cable is easier your first time).
2. Unlock your iPhone and if it asks "Trust This Computer?", tap **Trust**.
3. In Xcode's device dropdown, select your actual iPhone instead of a simulator.
4. Click  **Play**.
5. The first time, you'll probably get an error about needing a "developer account" or "signing." Go to Xcode → **Settings → Accounts**, sign in with your free Apple ID, then go back to your project's settings (click the project name in the left sidebar → **Signing & Capabilities**) and choose your name under "Team."
6. On your iPhone, the app might not open right away — you may need to go to **Settings → General → VPN & Device Management** on the iPhone and tell it to trust your developer profile.
7. **Very important:** Your iPhone and your Mac (running the server) both need to be connected to the **same Wi-Fi network**, otherwise the app can't reach the server.

---

## Common Problems (and how to fix them)

**"Could not connect to the server" / the app just spins or shows a network error**
- Make sure `main.py` is actually running in Terminal (Part 2, step 6). If you closed that window, the server stopped.
- Double check the IP address in `ApiClient.swift` matches your Mac's current IP address (it can change sometimes, especially after restarting your Wi-Fi).
- Make sure your iPhone (or simulator) and your Mac are on the same Wi-Fi network.

**"App Transport Security" error, or the request silently fails**
- This means iOS is blocking the non-secure `http://` connection. Make sure you added the exception in `Info.plist` mentioned in Part 3, step 6.

**The `.dylib` won't load / "image not found" error in Terminal**
- Rebuild it using the `clang` command in Part 2, step 5. Pre-built `.dylib` files often don't work if they were built on a different Mac or a different chip (like Intel vs Apple Silicon).

**"No module named flask" error**
- You probably forgot to activate your virtual environment. In Terminal, type `source venv/bin/activate` again before running `python3 main.py`.

**Xcode says "Signing for Axiom requires a development team"**
- Go to Xcode → Settings → Accounts, sign in with an Apple ID, then set your Team under Signing & Capabilities like mentioned in Part 4.

**Simulator works but real iPhone doesn't**
- This is almost always the Wi-Fi network issue or the trust/signing steps in Part 4, Option B. Double-check both.

**The AI voice doesn't play, it just uses a regular voice**
- That's normal if you didn't add an ElevenLabs API key, or if the key ran out of free credits. The app is designed to automatically fall back to the iPhone's built-in voice so it still works either way.

**Leaderboard or coins don't update**
- Make sure you're not running two servers at once (like leftover Terminal windows). Only one `python3 main.py` should be running.

---

## Quick Recap Checklist

- [ ] Downloaded Xcode
- [ ] Downloaded Python 3
- [ ] Backend folder has `main.py` and `libmathengine.dylib` together
- [ ] Ran `pip install -r requirements.txt`
- [ ] Rebuilt the `.dylib` with `clang`
- [ ] Server running (`python3 main.py`) and left open
- [ ] Updated `SERVER_BASE_URL` in `ApiClient.swift` with your Mac's IP
- [ ] Added App Transport Security exception in `Info.plist`
- [ ] (Optional) Added ElevenLabs API key
- [ ] Same Wi-Fi network for phone + Mac
- [ ] Signed the app with your Apple ID in Xcode (for real device)



That's it — you should now have Axiom up and running! 
