# Kodi 19+ Steamlink launcher for the Raspberry Pi and Generic x86_64 systems
A launcher and updater for running Steamlink on Raspberry Pi systems with LibreELEC.

## Background:
This Kodi addon-on was developed to enable Steamlink game streaming on LibreELEC systems.
Since LibreELEC is a "just enough" distribution dependencies for Steamlink are missing, requiring some extra steps to get things running. 
A simple add-on lets you install and launch Steamlink from within Kodi and stream games from your PC to your LibreELEC device.

More info on SteamLink for Raspberry Pi
https://help.steampowered.com/en/faqs/view/6424-467A-31D9-C6CB

More info on Steamlink for LibreELEC specifically can be found here:
https://forum.libreelec.tv/thread/14643-adding-steamlink-to-v9-0-0/

And for more general info about Steamlink:
https://steamcommunity.com/app/353380

## Prerequisites:
- [Raspberry Pi](https://libreelec.tv/downloads/raspberry/) with LibreELEC (Omega) 12+ installed
- Device is connected to a local network via ethernet (preferred) or Wi-Fi
- Gaming PC with Steam installed, connected to local network via ethernet (preferred) or Wi-Fi
- Enough temporary storage space on your LibreELEC device to install Steamlink (about 500 MB is needed)

### Raspberry Pi 3
Raspberry Pi 3 UNTESTED, but might need changes to LibreELEC's config: (based on moonlight-qt documentation)
- Login into your Pi 3 using SSH
- Make config writable: `mount -o remount,rw /flash/`
- In /flash/distroconfig.txt replace `dtoverlay=vc4-kms-v3d` with `dtoverlay=vc4-fkms-v3d` to enable fake KMS mode instead of full KMS
- In /flash/config.txt add `dtparam=audio=on` to enable audio in fake KMS mode
- Make config read only again: `mount -o remount,ro /flash/`
- Reboot the Pi 3

## Instructions:
### 1. Install this plugin.
- Download `plugin.program.steamlink.zip` from the [Releases](https://github.com/meekys/plugin.program.steamlink/releases/latest/) and store it on your Kodi device.
- In Kodi install Docker from the LibreELEC repository: Add-ons / Install from repository / LibreELEC Add-ons / Services / Docker 
- Reboot LibreELEC to ensure Docker works
- Go to Add-ons / Install from zip file
- Select `plugin.program.steamlink.zip`

### 2. Enable Remote Play in Steam on your Gaming PC

Open Steam, go to Steam -> Settings -> Remote Play (move slider to right)

### 3. Start Steamlink 
- Navigate to Games -> Steamlink
- Start Steamlink from the Games menu
- The plugin will ask you to install Steamlink, choose yes and wait a few minutes
- When the plugin has finished installing, Steamlink wil launch it
- Steamlink should start

### 4. Pair your gaming PC
Once your PC is recognised by Steamlink, you will be asked to enter a 4-digit code into Steam to pair Steamlink with Steam.
When the pairing is finished you can use Steamlink to adjust settings for streaming and launch games. Exit Steamlink and you will be returned to Kodi.

### 5. Updating
When you want to update Steamlink you can use the update menu in the add-on settings and press "Update Steamlink to the latest version".
The plugin will update Steamlink and will notify you when it's finished.

## What magic is happening in the background when installing and updating?
### Raspberry 4 on LibreELEC
Essentially the plugin uses Docker to download Debian Buster and install Steamlink and its dependencies
When that installation procedure has finished the plugin copies the needed executables and libraries from the Docker container and then destroys the container.
The plugin can use the copied files to launch Steamlink from Kodi without the extra overhead from Docker. 

## Known problems

### 'Internal error: Oops' while starting
When launching, if a controller is connected, it can often crash the kernel with an [oops](https://en.wikipedia.org/wiki/Linux_kernel_oops)

This issue is still under investigation, but occurs while executing the closed-source SteamLink binary, supplied by Valve

As a workaround, unplug any extra usb devices (including keyboards, mice and bluetooth dongles) while launching SteamLink, then re-connect them after SteamLink starts

### Help, it still doesn't work
You can always open an issue if Steamlink doesn't launch/update or the game menu doesn't work.
All configuration and streaming problems are probably related to Steamlink itself, you can report that on their own GitHub page: https://steamcommunity.com/app/353380/discussions/

## Thanks
Thanks to [veldenb](https://github.com/veldenb/plugin.program.moonlight-qt) for inspiration.

Thanks to [romank-sb](https://github.com/romank-sb) and [fuinril](https://github.com/fuinril) for the LibreElec 12 fixes and testing