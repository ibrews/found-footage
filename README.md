# found-footage

**Did your Mac tell you it couldn't save a screen recording? It probably saved it anyway. This finds it.**

When macOS screen recording fails with *"Could not save recording,"* the recording is usually still on your disk. macOS writes the finished file first, then **copies** it to wherever you asked it to go. It's the copy that fails — and the original survives, in a directory nobody thinks to look in.

`found-footage` looks in that directory, and the five other places recordings get stranded.

```
found-footage v0.1.0 — looking for recordings macOS couldn't save

  ● RPReplay_Final1787339210.mp4
    /Users/you/Library/Application Support/com.apple.replayd
    size     11.11 GB
    recorded 2026-08-21 15:06:50   (decoded from filename)
    length   0:18:03.92  ✓ playable
    video    3840x2160 @ 60 fps
    audio    2 tracks — most players and YouTube use only the FIRST.
             Check whether it's the one with sound in it.

  Found 1 file.

  Why the save probably failed
    ✗ Not enough free disk. Saving needs a second copy:
      recording is 11.11 GB, you have 8.63 GB free.
```

That is a real recovery — an 18-minute 4K60 recording that macOS reported as lost.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ibrews/found-footage/main/found-footage -o /usr/local/bin/found-footage
chmod +x /usr/local/bin/found-footage
```

No dependencies. It's one Bash script and it works on a stock Mac. If you have `ffmpeg` installed it will also tell you each file's length, resolution, and whether it's actually playable — useful, not required.

## Use

```bash
found-footage            # look and report. Touches nothing.
found-footage --rescue   # move whatever it found to ~/Desktop
found-footage --rescue --to "$HOME/Recovered Footage"
```

`--to` requires a directory. Quote paths that contain spaces. For a literal path
whose name begins with `-`, make it unambiguous with a relative or absolute path,
for example `--to ./-archive`.

Scanning is read-only by default, on purpose — you should see what's there before anything moves.

**Run it sooner rather than later.** These are staging directories, and macOS clears them on its own schedule. A recording that's recoverable this hour may not be tomorrow.

## Things to Try

1. **Run `found-footage` with nothing lost** — it should report "Nothing found" and exit non-zero. That's the safe case, and it confirms the tool never touches anything just by looking.
2. **Read the "Why the save probably failed" section after any find** — it compares the recording's size against your actual free disk, and checks whether the save folder you configured in Cmd-Shift-5 → Options still exists. A folder you moved or renamed months ago produces this exact error.
3. **Run `found-footage --rescue --to ~/Movies`** — every file found moves there with a filename built from its real recording time, decoded out of the raw `RPReplay_Final<epoch>.mp4` name. Nothing is overwritten; collisions get a numeric suffix.
4. **Check the audio-track warning if a recording had system audio** — macOS writes the mic and system audio as two separate tracks, and YouTube and most players read only the first. Recordings routinely ship silent because of this. `ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 yourfile.mp4` lists them.
5. **Pipe it** — `found-footage --quiet` prints bare paths and exits 1 when there's nothing, so you can wire it into a login item or a folder-action and never have to remember it exists.

## Where it looks

| Location | What lands there |
|---|---|
| `~/Library/Application Support/com.apple.replayd/` | Cmd-Shift-5 recordings whose save failed — **the one that usually has your file** |
| `$TMPDIR/com.apple.replayd/` | capture-in-progress scratch, usually cleared on failure |
| `$TMPDIR/TemporaryItems/` | general staging |
| `~/Library/Containers/com.apple.QuickTimePlayerX/.../Autosave Information/` | QuickTime "New Screen Recording" |
| `~/Library/Containers/com.apple.screencaptureui/Data/` | screenshot UI container — doesn't exist on every Mac; checked in case yours has it |

Confirmed on macOS 27 (Tahoe). Earlier versions may stage elsewhere; if you find a
recording somewhere not in this list, please open an issue with the path — that's the
most useful contribution this tool can get.

It does **not** search OBS, ScreenFlow, or CleanShot — those keep their own
crash-recovery folders, and you should check them by hand.

## Why `mv` and not `cp`

Rescue moves files rather than copying them. On the same volume a move is an instant rename that costs zero additional disk — which matters, because running out of disk is the most common reason the save failed in the first place. Copying an 11 GB file when you have 8 GB free just fails again.

## Limitations

- macOS only.
- If macOS already cleaned the staging directory, the file is gone. There's no undelete on APFS and this tool doesn't pretend otherwise.
- A truncated file (recording interrupted mid-write, no `moov` atom) is flagged but not repaired. [untrunc](https://github.com/anthwlock/untrunc) can sometimes rebuild those.

## License

MIT. See [LICENSE](LICENSE).

---

Built by [Alex Coulombe Presents](https://www.alexcoulombepresents.com) — after losing an 18-minute 4K recording and discovering it had been sitting on disk the whole time.
