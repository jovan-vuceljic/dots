# PyRadio Setup

This repository contains a custom configuration and station list for [PyRadio](https://github.com/coderholic/pyradio), a terminal-based radio player.

## Kitty Music Session

To get a full-screen, immersive music player experience, you can use a custom [Kitty terminal session](https://sw.kovidgoyal.net/kitty/sessions/).

The configuration file `music.conf` (found in your kitty config directory) sets up a layout that includes:
- A `pyradio` terminal.
- A `cava` terminal for audio visualization.
- A `pipes-rs` terminal for some visual flair.

### Launching the Session

Use keybind `$mainMod + R` or run the following command to launch the music session:

```bash
kitty --session ~/.config/kitty/music.conf
```

## Setup

1.  **Install PyRadio**: Ensure you have `pyradio` installed on your system.
2.  **Configuration**:
    *   Copy the `config` file to your PyRadio configuration directory (usually `~/.config/pyradio/config`).
    *   Copy the `stations.csv` file to your PyRadio directory.
3.  **Using Custom Stations**:
    *   PyRadio can be configured to use a custom stations file. Ensure your `config` points to the `stations.csv` provided here if you want to use this specific collection of stations.

## Station Sources

The stations in `stations.csv` are curated from various sources, often utilizing the [Radio Browser](https://www.radio-browser.info/) API.

### About Radio Browser
[Radio Browser](https://www.radio-browser.info/) is a community-driven database of internet radio stations. It is a free, open-source project that provides a massive API for accessing thousands of radio streams worldwide. It's a great resource for discovering new music and finding niche genres that might not be available on mainstream services.

## Alternatives to PyRadio

If you are looking for other ways to listen to internet radio in the terminal or via other interfaces, consider these alternatives:

*   **[Web Radio Clients](https://www.radio-browser.info/users)**: Many users of Radio Browser utilize various web-based players or custom scripts that interface directly with the Radio Browser API.
*   **[MPV (Command Line)](https://mpv.io/)**: Terminal player pyradio uses as a backend `mpv <stream_url>`
*   **[VLC (Command Line)](https://www.videolan.org/vlc/)**: You can play many radio streams directly from the terminal using `cvlc --play-and-exit <stream_url>`.

