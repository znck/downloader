# Downloader [![GitHub version](https://badge.fury.io/gh/znck%2Fdownloader.svg)](http://badge.fury.io/gh/znck%2Fdownloader)

A simple downloader to download large files.


## How to install?

Run this in your terminal to get the latest Downloader version:
```bash
curl -sS https://raw.githubusercontent.com/znck/downloader/master/install.sh | sudo bash
```

## How to use?

Downloader has simple commandline interface.

```bash
downloader <url> [<chunk size>]
```	

Default chunk size is 128mb but you can change it by a line to your `.bashrc` file

```bash
echo "export downloader_chunk_size=10" > "$HOME/.bashrc" # This will set chunk size to 10mb.
```
Default output directory is `~/Downloads` and you change this too.

```bash
echo "export downloader_output_dir=$HOME/Documents" > "$HOME/.bashrc"
```
