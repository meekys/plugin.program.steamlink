import sys
import steamlink
import xbmcaddon

# Configure addon
addon = xbmcaddon.Addon()

if (__name__ == '__main__'):
    if (len(sys.argv) -1 >= 1):
        if (sys.argv[1] == "update"):
            steamlink.update(addon)
        if (sys.argv[1] == "reset"):
            steamlink.reset(addon)
    else:
        steamlink.launch(addon)