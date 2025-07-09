import getpass
import json
import re
import io
from subprocess import Popen, PIPE, STDOUT, DEVNULL
import os
import pathlib
import xbmc
import xbmcgui
from xbmcvfs import translatePath

def launch(addon):
    # Initialise argument vars
    systemd_args = []
    steamlink_command = f'bash {get_resource_path("bin/launch.sh")}'
    steamlink_args = []

    systemd_args.append('--property=Type=exec')
    systemd_args.append('--unit=steamlink')

    # Check if systemd-run can be used in user-mode
    if os.environ.get('DBUS_SESSION_BUS_ADDRESS') is not None or os.environ.get('XDG_RUNTIME_DIR') is not None:
        systemd_args.append('--user')
    elif os.geteuid() != 0:
        # If systemd user-mode can't be used and the current kodi-user is not root, try sudo for switching (OSMC)
        steamlink_command = f'sudo -u {getpass.getuser()} {steamlink_command}'

    # Append addon path
    systemd_args.append(f'--setenv=ADDON_PROFILE_PATH="{get_addon_data_path()}"')

    # Create command to launch steamlink
    launch_command = 'systemd-run {} {}'.format(' '.join(systemd_args), steamlink_command)

    # Prepare logging
    logfile = f'{get_addon_data_path()}/steamlink.log'
    if os.path.exists(logfile):
        os.unlink(logfile)

    # Prepare the command
    command = f'{launch_command} ' + ' '.join(steamlink_args)
    stop_command = 'systemctl stop steamlink'

    # Log the command so debugging problems is easier
    xbmc.log(f'Launching steamlink: {command}', xbmc.LOGINFO)

    # Show a dialog
    launch_label = "" #addon.getLocalizedString(30202)
    message = launch_label

    p_dialog = xbmcgui.DialogProgress()
    p_dialog.create(addon.getLocalizedString(30200), launch_label)

    # Wait for the dialog to pop up
    xbmc.sleep(200)

    # Run the command
    exitcode = os.system(command)

    if exitcode != 0:
        # If steamlink did not start notify the user
        xbmc.log(f'Launching steamlink failed ({exitcode}): ' + command, xbmc.LOGERROR)
        p_dialog.close()
        dialog = xbmcgui.Dialog()
        dialog.ok(addon.getLocalizedString(30200), addon.getLocalizedString(30203))
        return

    # This is an estimate of how many lines of output there should be to guess the progress
    line_max = 3500
    line_nr = 0
    line = ''
    message=''
    sub_message=''

    # Wait for log file to exist
    xbmc.log(f'Waiting to read: {logfile}', xbmc.LOGINFO)
    while not os.path.exists(logfile):
        xbmc.sleep(50)

    # If the command was successful, display status messages and wait for steamlink to shut down kodi
    xbmc.log(f'Reading: {logfile}', xbmc.LOGINFO)
    with open(logfile, 'r', encoding='utf-8') as f:
        while True:
            if p_dialog.iscanceled():
                xbmc.log(f'Stopping steamlink: {stop_command}', xbmc.LOGINFO)
                exitcode = os.system(stop_command)

                if exitcode != 0:
                    # If steamlink did not stop notify the user
                    xbmc.log(f'Stopping steamlink failed ({exitcode}): ' + stop_command, xbmc.LOGERROR)
                    p_dialog.close()
                    dialog = xbmcgui.Dialog()
                    dialog.ok(addon.getLocalizedString(30200), 'Stop failed')

                return

            line = f.readline()

            if not line:
                xbmc.sleep(10)
                continue

            if line.startswith("###ACTION(kodi-stop)"):
                xbmc.log(f'steamlink: Waiting to exit...', xbmc.LOGINFO)
                xbmc.sleep(1000) # Keep dialog open until kodi stops
                xbmc.log(f'steamlink: Finished waiting', xbmc.LOGINFO)
                return

            if line.startswith("###ACTION(kodi-start)"):
                xbmc.log(f'steamlink: Finished waiting', xbmc.LOGINFO)
                return

            if line.startswith("###ERROR("):
                xbmc.log(f'steamlink: Finished waiting due to error', xbmc.LOGINFO)
                p_dialog.close()
                dialog = xbmcgui.Dialog()
                dialog.ok(addon.getLocalizedString(30200), 'Failed to launch')

                return

            match = re.search("###STATUS\((\d+)\):(.+)", line);
            if match is not None:
                match match.group(1): # Bump the progress along at certain milestones
                    case '110': # Steamlink dependencies (check and possibly installing)
                        xbmc.log(f'Line count: {line_nr}', xbmc.LOGINFO)
                        line_nr = 1800
                    case '120': # Starting steamlink 'shell'
                        xbmc.log(f'Line count: {line_nr}', xbmc.LOGINFO)
                        line_nr = line_max * 2

                message = match.group(2)
                sub_message = ''
            else:
                match = re.search("^(Step \d+/\d+|Get:\d+|Unpacking |Setting up |Downloading update|Unpacking update)", line);
                if match is not None:
                    sub_message = line

            percent = int(round(line_nr / line_max * 100))
            p_dialog.update(percent, f'{message}\n{sub_message}')
            line_nr += 1

def reset(addon):
    c_dialog = xbmcgui.Dialog()
    confirm_reset = c_dialog.yesno(f'{addon.getLocalizedString(30002)}', f'{addon.getLocalizedString(30003)}?')

    if confirm_reset is False:
        return

    cmd = f'bash {get_resource_path("bin/cleanup.sh")}'
    xbmc.log(cmd, xbmc.LOGINFO)
    exit_code = os.system(cmd)

def speaker_test(addon, speakers):
    dialog = xbmcgui.Dialog()
    service, device_name = get_kodi_audio_device()

    if service == 'ALSA':
        p_dialog = xbmcgui.DialogProgress()
        p_dialog.create('Speaker test', 'Initializing...')

        # Make sure Kodi does not keep the device occupied
        streamsilence_user_setting = get_kodi_setting('audiooutput.streamsilence')
        set_kodi_setting('audiooutput.streamsilence', 0)

        # Write new config file
        speaker_setup_write_alsa_config(addon)

        # Get Path for steamlink home
        home_path = get_steamlink_home_path()

        # Get device name foor surround sound
        non_lfe_speakers = speakers - 1
        device_name = 'surround{}1'.format(non_lfe_speakers)

        for speaker in range(speakers):
            # Display dialog text
            speaker_channel = addon.getSettingInt('alsa_surround_{}1_{}'.format(non_lfe_speakers, speaker))

            # Prepare dialog info
            dialog_percent = int(round((speaker + 1) / speakers * 100))
            dialog_text = 'Testing {} speaker on channel {}...' \
                .format(addon.getLocalizedString(30030 + speaker), speaker_channel)

            # Prepare command
            cmd = 'HOME="{}" speaker-test --nloops 1 --device {} --channels {} --speaker {}' \
                .format(home_path, device_name, speakers, speaker + 1)

            # For same reason the device is not always available, try until the command succeeds
            exit_code = 1
            while exit_code != 0:
                # Stop if user aborts test dialog
                if p_dialog.iscanceled():
                    break

                # Update dialog info
                p_dialog.update(dialog_percent, dialog_text)

                # Play test sound
                xbmc.log(cmd, xbmc.LOGINFO)
                exit_code = os.system(cmd)

                # If the command failed, tell the user and wait for a short time before retrying
                if exit_code != 0:
                    xbmc.log('Failed executing "{}"'.format(cmd), xbmc.LOGWARNING)

                    p_dialog.update(
                        dialog_percent,
                        'Waiting for {}.1 Surround audio device to become available...'.format(non_lfe_speakers)
                    )

                    xbmc.sleep(500)

            # Stop if user aborts test dialog
            if p_dialog.iscanceled():
                break

        # Restore user setting
        set_kodi_setting('audiooutput.streamsilence', streamsilence_user_setting)

        # Close the progress bar
        p_dialog.close()

    else:
        dialog.ok('Speaker test', 'Audio service is {}, not ALSA.\n\nTest aborted.'.format(service))

    addon.openSettings()


def speaker_setup_write_alsa_config(addon):
    asoundrc_template_path = get_resource_path('template/asoundrc')
    asoundrc_dir = "{}/.config/alsa".format(get_steamlink_home_path())
    asoundrc_path = "{}/asoundrc".format(asoundrc_dir)

    service, device_name = get_kodi_audio_device()
    template = pathlib.Path(asoundrc_template_path).read_text()

    # Only set default device if a non-default device is configured
    if device_name == 'default':
        template = template.replace('%default_device%', '')
    else:
        template = template.replace('%default_device%', 'pcm.!default "{}"'.format(device_name))

    # Set the device
    template = template.replace('%device%', device_name)

    for speakers in [6, 8]:
        for speaker in range(speakers):
            # Get setting id and channel
            setting_id = 'alsa_surround_{}1_{}'.format(speakers - 1, speaker)
            template_var = '%{}%'.format(setting_id)
            channel = addon.getSetting(setting_id)

            # Replace template var
            template = template.replace(template_var, channel)

    # Ensure dir exists
    if not os.path.exists(asoundrc_dir):
        os.mkdir(asoundrc_dir)

    # Write new config to asoundrc file
    pathlib.Path(asoundrc_path).write_text(template)
    xbmc.log('New ALSA config file written to {}'.format(asoundrc_path), xbmc.LOGINFO)


def get_resource_path(sub_path):
    return translatePath(pathlib.Path(__file__).parent.absolute().__str__() + '/resources/' + sub_path)


def get_addon_data_path(sub_path=''):
    return translatePath('special://profile/addon_data/plugin.program.steamlink' + sub_path)


def get_steamlink_home_path():
    return "{}/steamlink-home".format(get_addon_data_path())

def get_kodi_setting(setting):
    request = {
        'jsonrpc': '2.0',
        'method': 'Settings.GetSettingValue',
        'params': {'setting': setting},
        'id': 1
    }
    response = json.loads(xbmc.executeJSONRPC(json.dumps(request)))
    return response['result']['value']


def set_kodi_setting(setting, value):
    request = {
        'jsonrpc': '2.0',
        'method': 'Settings.SetSettingValue',
        'params': {'setting': setting, 'value': value},
        'id': 1
    }
    json.loads(xbmc.executeJSONRPC(json.dumps(request)))


def get_kodi_audio_device():
    return get_kodi_setting('audiooutput.audiodevice').split(':', 1)
