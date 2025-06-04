---
title: macOS Catalina EDID Override AKA HDMI color fix
date: 2019-10-07T22:26:07+02:00
draft: false
---
HDMI connections from your Mac to monitor can be a pain in the ass. There is a chance that macOS
will detect your monitor as a TV and set the color space to YCbCr. You will get wrong colors
and sometimes blurry fonts.

If you're having this problem, like me, you know the fix: a patched EDID created with this
[little Ruby script](https://embdev.net/attachment/168316/patch-edid.rb).

The installation of this EDID override could be tedious since the release of El Capitan, as SIP won't let you
access the necessary system files. Just disable it in recovery mode, copy the file and enable
it again. Sucks, but works just fine.

Now, Catalina is out for a few hours and has a new way to annoy people who need EDID overrides.
All system-related directories and files are read-only, regardless of the status of SIP.

Fortunately Apple was not crazy enough to disable the write access completely.

## Help is on the way, ETA 0 seconds!

1. Patch your EDID
2. Boot into recovery mode with CMD+R
3. Login with your user
4. Open Disk Utility, select your volume (in most cases `Macintosh HD`) and mount it with your password (yes, again)
5. Close the Disk Utility and open a Terminal window
6. Copy the directory with the patched EDID to
   `/Volumes/$VOLUME_NAME/System/Library/Displays/Contents/Resources/Overrides`
7. Reboot and enjoy the right colors again

Here's an example of the shell commands:

```shell
cd /Volumes/Macintosh\ HD/System/Library/Displays/Contents/Resources/Overrides
cp -rf /Volumes/Macintosh\ HD/Users/webcodr/DisplayVendorID-5a63 .
```

**Don't forget to use the correct volume and user names!**

## Dear Apple

Just add a simple solution to select the HDMI color
space. A simple shell commando with `sudo` would suffice or at least let us use an override directory
within the user library as it was possible many years ago. It just sucks to do this after every
macOS upgrade and every time you improve system security, it gets harder.

Please, don't forget us powers users ...