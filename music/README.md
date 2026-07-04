# replacing the soundtrack

The game ships with a small generated tune (see `game/autoload/sfx.gd`,
`_make_music()`). It is only a fallback — you can replace it without touching
any code, in either of two ways:

## 1. In the project (ships with the build)

Drop a file named exactly one of:

```
music/track.ogg      (recommended)
music/track.mp3
music/track.wav
```

into this folder and run the game from the editor, or let CI re-export.
OGG and MP3 loop automatically; WAV loops via an end-of-stream restart.

## 2. At runtime (no rebuild — works on the shipped app)

Put a file named `music.ogg`, `music.mp3`, or `music.wav` into the game's
user-data folder and relaunch:

- **macOS**: `~/Library/Application Support/Godot/app_userdata/Two Microseconds/`
- **Linux**: `~/.local/share/godot/app_userdata/Two Microseconds/`
- **Windows**: `%APPDATA%\Godot\app_userdata\Two Microseconds\`

The runtime override wins over the project file, which wins over the
generated tune. Music volume is `MUSIC_DB` at the top of
`game/autoload/sfx.gd` (default −12 dB).
