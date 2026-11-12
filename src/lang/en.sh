# shellcheck shell=bash disable=SC2034,SC1111
# English UI strings. %s placeholders are filled in with printf.

L_DEFAULT_SUPPORT="your administrator"

L_BTN_OK="OK"
L_BTN_CANCEL="Cancel"
L_BTN_RETRY="Try Again"
L_BTN_START="Start"
L_BTN_CONNECT="Connect"
L_BTN_CONFIRM="Confirm"
L_BTN_GOTIT="Got It"
L_BTN_LATER="Not Now"
L_BTN_INSTALL="Install"

# Installer
L_INTRO_HEAD="$APP_NAME Setup"
L_INTRO_REMOTE="This setup lets you open the office NAS securely, both in the office and from anywhere else. It takes about 5 minutes."
L_INTRO_OFFICE="This setup lets you open the office NAS from this Mac. It takes a few minutes."
L_INTRO_ASK="During setup you will be asked for:"
L_INTRO_ITEM_NAS="• your NAS user name and password"
L_INTRO_ITEM_MAC="• your Mac password (to install the Cloudflare WARP app)"
L_INTRO_ITEM_LOGIN="• a sign-in with your $LOGIN_ACCOUNT account"
L_INTRO_TAIL="After you press Start this window closes; setup continues in the background and opens each window it needs. If macOS shows a “Background Items Added” notification, leave it on - the NAS folders depend on it."
L_ALREADY_RUNNING="$APP_NAME setup is already running. Please follow the open windows."
L_STATUS_ACCOUNT="Checking your NAS account…"
L_STATUS_WARP="Connecting WARP…"
L_STATUS_LAUNCHERS="Preparing the folder icons…"
L_STARTED="Setup has started…"
L_COPY_FAILED="The setup files could not be copied. Copy the app to your Desktop and open it from there."
L_FAILED_HEAD="Setup could not be completed."
L_FAILED_TAIL="You can start setup again; finished steps are not repeated. If the problem persists, send a screenshot of this window to $SUPPORT_CONTACT."
L_UNEXPECTED="Something unexpected went wrong."
L_CANCELLED="Setup was cancelled."

L_NAS_UNREACHABLE_WARP="The NAS could not be reached. Click the WARP icon in the menu bar and make sure it is Connected; if macOS asked for VPN permission, choose Allow. Then start setup again."
L_NAS_UNREACHABLE_OFFICE="The NAS could not be reached. This setup only works on the office network; please run it again while connected there."
L_ENTER_CREDS="Please enter your NAS user name and password in the window that opens."
L_ASK_USER="Your NAS user name (e.g. Jane Doe):"
L_USER_EMPTY="The user name cannot be empty."
L_ASK_PASS="Please enter your NAS password:"
L_BAD_CREDS="The user name or password is incorrect. Make sure the user name is spelled exactly as on the NAS, including any accented letters."
L_RETRY_N="Please try again (%s/3)."
L_NO_MORE_TRIES="Three attempts failed, so setup has stopped. Please check your user name and password with $SUPPORT_CONTACT."
L_CREDS_FAILED_3="The user name or password was wrong three times."
L_CONN_PROBLEM="Something went wrong while connecting to the NAS (code %s). Wait a few seconds and press Try Again; if it keeps happening, contact $SUPPORT_CONTACT."

L_WARP_FOREIGN="Cloudflare WARP on this Mac is managed by another organisation. Please contact $SUPPORT_CONTACT."
L_WARP_DOWNLOADING="Downloading the connection app (Cloudflare WARP), please wait."
L_WARP_DL_FAIL="WARP could not be downloaded. Check your internet connection."
L_WARP_SIG_FAIL="The downloaded file's signature could not be verified, so setup has stopped."
L_WARP_ADMIN_PROMPT="$APP_NAME needs your Mac password to install the connection app (Cloudflare WARP)."
L_WARP_CANCELLED="WARP installation was cancelled (no Mac password entered)."
L_WARP_INSTALL_FAIL="WARP could not be installed. If your Mac password was not accepted you may not be an administrator on this Mac; contact $SUPPORT_CONTACT."
L_WARP_INCOMPLETE="WARP installation did not finish."
L_LOGIN_NOTIFY="Please sign in with your $LOGIN_ACCOUNT account in the browser."
L_LOGIN_DIALOG="Sign in with your $LOGIN_ACCOUNT account on the page that opened in your browser. Setup continues by itself once you are signed in."
L_WARP_SWITCH="Cloudflare WARP on this Mac is enrolled in another account (%s). Do you want to move it to the $ORG_NAME account? The current enrolment will be removed."
L_WARP_PERSONAL="personal"
L_WARP_SWITCH_DECLINED="Cancelled; the current WARP enrolment was not changed."
L_LOGIN_PROGRESS="Finish signing in in the browser... (minute %s of 10)"
L_LOGIN_TIMEOUT="Sign-in was not completed within 10 minutes."
L_WARP_NOT_CONNECTED="IMPORTANT: WARP is not connected yet. To reach the NAS from outside the office, click the WARP icon in the menu bar and connect; if macOS asks for VPN permission, choose Allow."
L_WARP_SKIPPED_OFFICE="IMPORTANT: WARP setup was not completed. The NAS works in the office; run setup again for access from elsewhere."
L_WARP_FAILED_OFFICE="IMPORTANT: WARP could not be installed. The NAS works in the office, but for access from elsewhere please contact $SUPPORT_CONTACT."

L_NO_SHARES="No NAS folders you have access to were found. Please contact $SUPPORT_CONTACT."
L_AGENT_NOT_RUNNING="The $APP_NAME background task is not running. Allow it under System Settings > General > Login Items, or run $APP_NAME setup again."
L_LOC_DESKTOP="Your NAS folders are in the \"$FOLDER_NAME\" folder on your Desktop."
L_LOC_HOME="Your NAS folders are in the \"$FOLDER_NAME\" folder in your home folder (Finder > Go > Home)."
L_FINAL_TITLE="WARNING: FILES AND FOLDERS YOU DELETE IN NAS FOLDERS ARE DELETED FROM THE NAS, NOT JUST FROM YOUR MAC."
L_FINAL_DONE="Setup is complete."
L_FINAL_HOWTO="Double-click a folder icon to open it; the folder opens in Finder within a few seconds."
L_FINAL_WHERE="Files in an opened folder live on the NAS, not on your Mac; every change and every deletion applies to the NAS directly."
L_FINAL_SIDEBAR="Tip: drag the \"$FOLDER_NAME\" folder into Favorites in the Finder sidebar to keep your NAS folders one click away."
L_FINAL_WARP="Outside the office, make sure the WARP app in the menu bar is connected."

# Background task
L_SETUP_INCOMPLETE="$APP_NAME setup is not complete. Please run setup again."
L_UNREACHABLE_WARP="The NAS cannot be reached.

If you are outside the office, click the WARP icon in the menu bar and make sure it is Connected. If WARP asks you to sign in, sign in again with your $LOGIN_ACCOUNT account. Then click the folder again."
L_UNREACHABLE_NOWARP="The NAS cannot be reached.

Cloudflare WARP on this Mac is not enrolled in the $ORG_NAME account. Please run $APP_NAME setup again or contact $SUPPORT_CONTACT."
L_UNREACHABLE_OFFICE="The NAS cannot be reached. NAS folders can only be opened on the office network."
L_NO_PASSWORD="The NAS password was not found. Please run setup again."
L_PW_CHANGED="Your NAS password seems to have changed.

If you do not know your new password, ask $SUPPORT_CONTACT for one and enter it below."
L_PW_REJECTED="The password you entered was not accepted. Please check it with $SUPPORT_CONTACT and click the folder again."
L_OLD_MOUNT_BUSY="The old connection of \"%s\" could not be closed (a file may be open). Close open files and try again."
L_OPEN_FAILED="\"%s\" could not be opened. Try again in a few seconds; if it keeps happening, contact $SUPPORT_CONTACT."

# Updates
L_UPDATE_AVAILABLE="A new version of $APP_NAME is available (%s).

%s

Install it now? It takes a few seconds and does not affect open NAS folders."
L_UPDATE_DONE="$APP_NAME was updated to version %s."
L_UPDATE_FAILED="The $APP_NAME update could not be installed; the current version stays in use."

# Repair / uninstall (setup app opened again)
L_BTN_UPDATE="Update"
L_BTN_REINSTALL="Reinstall"
L_BTN_UNINSTALL="Uninstall"
L_INSTALLED_SAME="$APP_NAME is already installed on this Mac (version %s). Do you want to reinstall it or uninstall it?"
L_INSTALLED_UPDATE="$APP_NAME %s is installed on this Mac. This package contains version %s. Do you want to update or uninstall?"
L_INSTALLED_NEWER="A newer version of $APP_NAME (%s) is installed on this Mac than the one in this package (%s). From here you can only uninstall it."
L_UNINSTALL_CONFIRM="Uninstall $APP_NAME? The folder icons, the background task and the NAS password saved on this Mac are removed. Files on the NAS are not touched. Cloudflare WARP stays installed."
L_UNINSTALL_BUSY="Some NAS folders could not be closed because files on them are open. Close those files and try again. Nothing was removed."
L_UNINSTALL_DONE="$APP_NAME has been removed from this Mac. Cloudflare WARP is still installed; if you no longer need it, ask $SUPPORT_CONTACT to remove it."
