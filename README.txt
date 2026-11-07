NBA 2K17 LAUNCHER / SWITCHER
============================
Play NBA 2K17 on both Revival and Back2Back on the same PC without them wrecking each other's
saves. One window, two tiles: click the server you want.

WHY YOU NEED IT
---------------
Both clients run the game as Steam app 480, so both use the SAME Steam save folder:
  Steam\userdata\<your account>\480\remote
Each client uploads whatever is in that folder to its own cloud the moment you press Play
(Back2Back also when you quit). Launch Revival while Back2Back's saves are sitting there and
Revival's cloud gets Back2Back's players (they show up as 55 OVR), and the other way round.
The launcher parks one client's saves and puts the other client's saves in place before it
starts the client. One click, no thinking.

STARTING FROM SCRATCH (the smooth order)
----------------------------------------
1. Steam installed and signed in, and your NBA 2K17 game folder on disk.
2. Install Revival, sign in, add NBA 2K17 (point it at NBA2K17.exe in your game folder).
3. Unzip this launcher and run Install.cmd. It sees Revival's game folder and no Back2Back yet,
   and offers to prepare Back2Back's own copy of the game right away ("<folder>-Back2Back",
   5-15 minutes, ~70 GB free needed). Say yes. It also puts the icons on your desktop.
4. Install Back2Back, sign in with Steam, link Discord and join their server. When it asks for the
   game, pick NBA2K17.exe inside the "-Back2Back" folder. Its checklist is green from the start.
   Then click "Re-run setup" in the launcher window (or run Install.cmd again).
5. Open "NBA 2K17 Launcher" and click a tile. The first launch of each client restarts Steam once
   (the client registers itself) and Windows may ask to allow the game through the firewall: Allow.
You never need to start the game by hand first; the launcher creates the Steam save folder itself.

Already have both clients installed on one game folder? Also fine: Install.cmd offers to copy the
game for Back2Back and points Back2Back at the copy; afterwards press FIX OTHER CLIENT CONFLICT
and QUICK CHECK in Back2Back's Settings once.

WHAT YOU NEED (the launcher cannot do these for you)
----------------------------------------------------
- Steam, signed in. Both clients run the game through Steam and tie progress to your Steam account.
- The clients themselves, installed and signed in: Revival (Steam link) and Back2Back (Steam link,
  Discord link, membership of their Discord server). These are accounts, so they are yours to do.
- Two game folders, one per client. The launcher makes the second one (see above).

INSTALL (2 minutes, plus a copy of the game if needed)
-----------------------------------------------------
1. Unzip this folder somewhere permanent, for example Documents\NBA2K17-Switcher.
   (If Windows blocks a .cmd with "Windows protected your PC": More info > Run anyway.
   Or right-click the zip before unzipping > Properties > tick Unblock.)
2. Close both launchers and run Install.cmd. It finds Steam, the save folder and both launchers,
   and then:
   - If Revival is set up and Back2Back isn't yet, it offers to prepare Back2Back's copy of the
     game now (see "Starting from scratch").
   - If both clients use the same game folder (the normal state after installing both), it
     offers to fix that on the spot: it copies the game to "<folder>-Back2Back" (5-15 minutes,
     needs ~70 GB free), points Back2Back at the copy and takes Back2Back's files out of the
     original. Afterwards open Back2Back > Settings, press FIX OTHER CLIENT CONFLICT, then
     QUICK CHECK, and start each client once (Steam restarts once per client).
   - It asks ONE question: which client did you play last on this PC (R, B, or U if unsure).
     Answer honestly: that tells it whose saves are in the folder right now. If you have been
     switching by hand and the folder is a mix, answer U: the first click on each tile then parks
     the mix as a safety copy and lets that client pull its own cloud copy.
   - It builds the little "NBA 2K17 Launcher.exe" and puts the icons on your desktop:
       NBA 2K17 Launcher   (the window)     Play Revival / Play Back2Back   (one-click shortcuts)
   The window does all of the same on its first start, so opening NBA2K17-Launcher.ps1 directly
   works too. Split.cmd exists only as the manual fallback for the copy step.

EVERY DAY
---------
Open "NBA 2K17 Launcher" and click REVIVAL or BACK2BACK. The window shows whose saves are in
place, what is parked, and a log of what it just did. Then press Play in the client as usual.
The tiles grey out while the game is running or while Back2Back is still saving to its cloud.
"Play Revival" / "Play Back2Back" on the desktop do the same thing without the window.

Habits that keep it bulletproof:
- Always start the game through the launcher (or the two shortcuts).
- Quit the game normally. After Back2Back, wait for its launcher to say "Progress saved".
- If you also play Revival on another device: press Play in Revival once before you switch away
  from it. Revival only uploads your saves at Play, never when the game closes.

THE "CLOUD OR LOCAL" QUESTION
-----------------------------
Revival asks this only when your files changed since your last upload AND its cloud changed too
(another device uploaded in between). Back2Back has the same question ("Choose local or cloud
progress"). The answer is the side you played most recently:
- You play on ONE PC only: this question should never appear. If it does, something unusual
  happened; Local is normally right because the launcher just put your own newest saves back.
  Cloud is the emergency answer if you are not sure whose files are in the folder.
- You play on SEVERAL devices: Cloud if you played on the other device more recently, otherwise Local.

WHERE THINGS ARE
----------------
Everything is in the "data" folder next to the scripts (NBA2K17-Switcher\data\):
  parking\Revival\remote      Revival's parked saves while Back2Back is in use
  parking\Back2Back\remote    Back2Back's parked saves while Revival is in use
  history\                    a zip of the outgoing saves at every switch (last 30 kept)
  switcher.log                what the launcher did, with times
  state.json                  which client's saves are currently in place
"Open data folder" in the window (or Status.cmd) shows all of this. Don't move the
NBA2K17-Switcher folder after installing; if you do, run Install.cmd again.

IF SOMETHING GOES WRONG
-----------------------
- "NBA 2K17 is still running": quit the game, try again.
- "Back2Back is still saving to its cloud": wait for "Progress saved" in its launcher, try again.
- "No parked saves for X yet": first time for that client on this PC. The folder is left empty and
  the client downloads its own cloud copy. If it asks, choose Cloud.
- You switched by hand or something looks off: the launcher warns you when the folder does not
  look like the saves it expected and lets you cancel.
- Need an older set back: the zips in data\history\ hold every outgoing set, newest first. Close
  the game and both launchers, empty the Steam save folder, unzip the set you want into it, then
  click "Set up again" and answer the question with that client.
- The exe won't build (no C# compiler): the desktop icon opens the window directly instead.
- "Your device blocked it" / "This app has been blocked": Windows 11's Smart App Control refuses unsigned
  programs, and the locally built exe is unsigned. Run Install.cmd again: when that feature is on, the
  desktop icon is made to open the window through PowerShell, which still works.

UPDATES
-------
The launcher checks GitHub for a newer version each time it opens (update.json names the
repository). When one is out, an "Update to X" button appears at the bottom; click it and the
new files are installed over the old ones, your data folder is kept, and the launcher restarts.
Without the window: Update.cmd does the same from a console.

If you are the one publishing: edit the version number at the top of Switcher.Core.ps1
(for example '2.2'), run Make-Zip.cmd, then on GitHub create a release with tag v2.2 and drag
the zip onto it. Everyone's launcher offers the update the next time it opens.

UNINSTALL
---------
Delete the desktop icons and the NBA2K17-Switcher folder (take anything you want from
data\parking\ first). Nothing else was changed on the PC.

MANUAL SPLIT (if you would rather not run Split.cmd)
-----------------------------------------------------
1. Close both launchers and the game.
2. Copy the whole game folder to a new folder next to it, e.g. "NBA2K17PC-Back2Back", leaving out
   Revival's files: RV, dinput8_shim.ini, every .revival-* file, revival_loader.log, icon.ico.
3. In the ORIGINAL folder delete Back2Back's files: b2b17_arena_*.iff, rebirth_dinput8.ini,
   the cdn and store folders, and the .rebirth2k_backups folder (first copy the dinput8.dll.*
   file from .rebirth2k_backups\native-setup over dinput8.dll; that is Revival's loader).
4. Open Back2Back > Settings > SELECT GAME FOLDER > pick NBA2K17.exe in the new folder,
   then FIX OTHER CLIENT CONFLICT, then QUICK CHECK. The checklist should read "Everything is ready".
5. Start each client once; each registers its own Steam shortcut (Steam restarts), and Windows may
   ask to allow the game through the firewall for the new folder: Allow.

FILES IN THIS FOLDER
--------------------
NBA2K17-Launcher.ps1   the window            Switcher.Core.ps1   the engine (shared)
NBA2K17-Switcher.ps1   command-line version  Launcher\           source + icon for the exe
update.json            which GitHub repository to check for new versions
Install.cmd  Split.cmd  Status.cmd  Update.cmd  Make-Zip.cmd  Play Revival.cmd  Play Back2Back.cmd
