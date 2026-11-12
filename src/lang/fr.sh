# shellcheck shell=bash disable=SC2034,SC1111
# French UI strings. %s placeholders are filled in with noc_fmt.

L_DEFAULT_SUPPORT="votre administrateur"

L_BTN_OK="OK"
L_BTN_CANCEL="Annuler"
L_BTN_RETRY="Réessayer"
L_BTN_START="Commencer"
L_BTN_CONNECT="Se connecter"
L_BTN_CONFIRM="Confirmer"
L_BTN_GOTIT="Compris"
L_BTN_LATER="Plus tard"
L_BTN_INSTALL="Installer"

# Installer
L_INTRO_HEAD="Installation de $APP_NAME"
L_INTRO_REMOTE="Cette installation vous permet d'ouvrir le NAS du bureau en toute sécurité, au bureau comme ailleurs. Elle dure environ 5 minutes."
L_INTRO_OFFICE="Cette installation vous permet d'ouvrir le NAS du bureau depuis ce Mac. Elle dure quelques minutes."
L_INTRO_ASK="Pendant l'installation, on vous demandera :"
L_INTRO_ITEM_NAS="• votre nom d'utilisateur et votre mot de passe du NAS"
L_INTRO_ITEM_MAC="• le mot de passe de votre Mac (pour installer l'app Cloudflare WARP)"
L_INTRO_ITEM_LOGIN="• une connexion avec votre compte $LOGIN_ACCOUNT"
L_INTRO_TAIL="Après « Commencer », cette fenêtre se ferme ; l'installation continue en arrière-plan et ouvre les fenêtres nécessaires l'une après l'autre. Si macOS affiche la notification « Éléments d'arrière-plan ajoutés », laissez-la activée : les dossiers du NAS en dépendent."
L_ALREADY_RUNNING="L'installation de $APP_NAME est déjà en cours. Suivez les fenêtres ouvertes."
L_STATUS_ACCOUNT="Vérification de votre compte NAS…"
L_STATUS_WARP="Connexion de WARP…"
L_STATUS_LAUNCHERS="Préparation des icônes de dossier…"
L_STARTED="L'installation a commencé…"
L_COPY_FAILED="Les fichiers d'installation n'ont pas pu être copiés. Copiez l'app sur le Bureau et ouvrez-la depuis là."
L_FAILED_HEAD="L'installation n'a pas pu se terminer."
L_FAILED_TAIL="Vous pouvez relancer l'installation ; les étapes terminées ne sont pas répétées. Si le problème persiste, envoyez une capture de cette fenêtre à $SUPPORT_CONTACT."
L_UNEXPECTED="Un problème inattendu est survenu."
L_CANCELLED="L'installation a été annulée."

L_NAS_UNREACHABLE_WARP="Le NAS est injoignable. Cliquez sur l'icône WARP dans la barre des menus et vérifiez qu'elle est connectée (Connected) ; si macOS a demandé une autorisation VPN, choisissez « Autoriser ». Relancez ensuite l'installation."
L_NAS_UNREACHABLE_OFFICE="Le NAS est injoignable. Cette installation ne fonctionne que sur le réseau du bureau ; relancez-la depuis ce réseau."
L_ENTER_CREDS="Saisissez votre nom d'utilisateur et votre mot de passe du NAS dans la fenêtre qui s'ouvre."
L_ASK_USER="Votre nom d'utilisateur du NAS (par ex. Marie Dupont) :"
L_USER_EMPTY="Le nom d'utilisateur ne peut pas être vide."
L_ASK_PASS="Saisissez votre mot de passe du NAS :"
L_BAD_CREDS="Le nom d'utilisateur ou le mot de passe est incorrect. Vérifiez que le nom d'utilisateur est écrit exactement comme sur le NAS, accents compris."
L_RETRY_N="Veuillez réessayer (%s/3)."
L_NO_MORE_TRIES="Trois tentatives ont échoué ; l'installation est arrêtée. Vérifiez votre nom d'utilisateur et votre mot de passe avec $SUPPORT_CONTACT."
L_CREDS_FAILED_3="Le nom d'utilisateur ou le mot de passe était faux trois fois."
L_CONN_PROBLEM="Un problème est survenu lors de la connexion au NAS (code %s). Patientez quelques secondes puis cliquez sur « Réessayer » ; si cela se reproduit, contactez $SUPPORT_CONTACT."

L_WARP_FOREIGN="Cloudflare WARP sur ce Mac est géré par une autre organisation. Contactez $SUPPORT_CONTACT."
L_WARP_DOWNLOADING="Téléchargement de l'app de connexion (Cloudflare WARP), veuillez patienter."
L_WARP_DL_FAIL="WARP n'a pas pu être téléchargé. Vérifiez votre connexion Internet."
L_WARP_SIG_FAIL="La signature du fichier téléchargé n'a pas pu être vérifiée ; l'installation est arrêtée."
L_WARP_ADMIN_PROMPT="$APP_NAME a besoin du mot de passe de votre Mac pour installer l'app de connexion (Cloudflare WARP)."
L_WARP_CANCELLED="L'installation de WARP a été annulée (aucun mot de passe du Mac saisi)."
L_WARP_INSTALL_FAIL="WARP n'a pas pu être installé. Si le mot de passe de votre Mac a été refusé, vous n'êtes peut-être pas administrateur de ce Mac ; contactez $SUPPORT_CONTACT."
L_WARP_INCOMPLETE="L'installation de WARP ne s'est pas terminée."
L_LOGIN_NOTIFY="Connectez-vous dans le navigateur avec votre compte $LOGIN_ACCOUNT."
L_LOGIN_DIALOG="Connectez-vous avec votre compte $LOGIN_ACCOUNT sur la page ouverte dans votre navigateur. L'installation reprend d'elle-même une fois la connexion faite."
L_WARP_SWITCH="Cloudflare WARP sur ce Mac est inscrit à un autre compte (%s). Voulez-vous le transférer vers le compte $ORG_NAME ? L'inscription actuelle sera supprimée."
L_WARP_PERSONAL="personnel"
L_WARP_SWITCH_DECLINED="Annulé ; l'inscription WARP actuelle n'a pas été modifiée."
L_LOGIN_PROGRESS="Terminez la connexion dans le navigateur… (minute %s sur 10)"
L_LOGIN_TIMEOUT="La connexion n'a pas été terminée en 10 minutes."
L_WARP_NOT_CONNECTED="IMPORTANT : WARP n'est pas encore connecté. Pour accéder au NAS hors du bureau, cliquez sur l'icône WARP dans la barre des menus et connectez-vous ; si macOS demande une autorisation VPN, choisissez « Autoriser »."
L_WARP_SKIPPED_OFFICE="IMPORTANT : la configuration de WARP n'est pas terminée. Le NAS fonctionne au bureau ; relancez l'installation pour y accéder d'ailleurs."
L_WARP_FAILED_OFFICE="IMPORTANT : WARP n'a pas pu être installé. Le NAS fonctionne au bureau ; pour y accéder d'ailleurs, contactez $SUPPORT_CONTACT."

L_NO_SHARES="Aucun dossier du NAS auquel vous avez accès n'a été trouvé. Contactez $SUPPORT_CONTACT."
L_AGENT_NOT_RUNNING="La tâche d'arrière-plan de $APP_NAME ne fonctionne pas. Autorisez-la dans Réglages Système > Général > Ouverture, ou relancez l'installation de $APP_NAME."
L_LOC_DESKTOP="Vos dossiers du NAS se trouvent dans le dossier « $FOLDER_NAME » sur le Bureau."
L_LOC_HOME="Vos dossiers du NAS se trouvent dans le dossier « $FOLDER_NAME » de votre dossier de départ (Finder > Aller > Départ)."
L_FINAL_TITLE="ATTENTION : LES FICHIERS ET DOSSIERS QUE VOUS SUPPRIMEZ DANS LES DOSSIERS DU NAS SONT SUPPRIMÉS DU NAS, PAS SEULEMENT DE VOTRE MAC."
L_FINAL_DONE="L'installation est terminée."
L_FINAL_HOWTO="Double-cliquez sur une icône de dossier pour l'ouvrir ; le dossier s'ouvre dans le Finder en quelques secondes."
L_FINAL_WHERE="Les fichiers d'un dossier ouvert sont sur le NAS, pas sur votre Mac ; chaque modification et chaque suppression s'applique directement au NAS."
L_FINAL_SIDEBAR="Astuce : faites glisser le dossier « $FOLDER_NAME » dans les Favoris de la barre latérale du Finder pour garder vos dossiers du NAS à portée de clic."
L_FINAL_WARP="Hors du bureau, vérifiez que l'app WARP de la barre des menus est connectée."

# Background task
L_SETUP_INCOMPLETE="L'installation de $APP_NAME n'est pas terminée. Relancez-la."
L_UNREACHABLE_WARP="Le NAS est injoignable.

Si vous n'êtes pas au bureau, cliquez sur l'icône WARP dans la barre des menus et vérifiez qu'elle est connectée (Connected). Si WARP demande une connexion, reconnectez-vous avec votre compte $LOGIN_ACCOUNT. Cliquez ensuite à nouveau sur le dossier."
L_UNREACHABLE_NOWARP="Le NAS est injoignable.

Cloudflare WARP sur ce Mac n'est pas inscrit au compte $ORG_NAME. Relancez l'installation de $APP_NAME ou contactez $SUPPORT_CONTACT."
L_UNREACHABLE_OFFICE="Le NAS est injoignable. Les dossiers du NAS ne s'ouvrent que sur le réseau du bureau."
L_NO_PASSWORD="Le mot de passe du NAS est introuvable. Relancez l'installation."
L_PW_CHANGED="Votre mot de passe du NAS semble avoir changé.

Si vous ne connaissez pas le nouveau, demandez-le à $SUPPORT_CONTACT et saisissez-le ci-dessous."
L_PW_REJECTED="Le mot de passe saisi a été refusé. Vérifiez-le avec $SUPPORT_CONTACT puis cliquez à nouveau sur le dossier."
L_OLD_MOUNT_BUSY="L'ancienne connexion de « %s » n'a pas pu être fermée (un fichier est peut-être ouvert). Fermez les fichiers ouverts et réessayez."
L_OPEN_FAILED="« %s » n'a pas pu être ouvert. Réessayez dans quelques secondes ; si cela se reproduit, contactez $SUPPORT_CONTACT."

# Updates
L_UPDATE_AVAILABLE="Une nouvelle version de $APP_NAME est disponible (%s).

%s

L'installer maintenant ? Cela prend quelques secondes et n'affecte pas les dossiers du NAS ouverts."
L_UPDATE_DONE="$APP_NAME a été mis à jour vers la version %s."
L_UPDATE_FAILED="La mise à jour de $APP_NAME n'a pas pu être installée ; la version actuelle reste en service."

# Repair / uninstall (setup app opened again)
L_BTN_UPDATE="Mettre à jour"
L_BTN_REINSTALL="Réinstaller"
L_BTN_UNINSTALL="Désinstaller"
L_INSTALLED_SAME="$APP_NAME est déjà installé sur ce Mac (version %s). Voulez-vous le réinstaller ou le désinstaller ?"
L_INSTALLED_UPDATE="$APP_NAME %s est installé sur ce Mac. Ce paquet contient la version %s. Voulez-vous mettre à jour ou désinstaller ?"
L_INSTALLED_NEWER="La version de $APP_NAME installée sur ce Mac (%s) est plus récente que celle de ce paquet (%s). D'ici, vous pouvez seulement le désinstaller."
L_UNINSTALL_CONFIRM="Désinstaller $APP_NAME ? Les icônes de dossier, la tâche d'arrière-plan et le mot de passe du NAS enregistré sur ce Mac sont supprimés. Les fichiers du NAS ne sont pas touchés. Cloudflare WARP reste installé."
L_UNINSTALL_BUSY="Certains dossiers du NAS n'ont pas pu être fermés, car des fichiers y sont ouverts. Fermez ces fichiers et réessayez. Rien n'a été supprimé."
L_UNINSTALL_DONE="$APP_NAME a été supprimé de ce Mac. Cloudflare WARP reste installé ; si vous n'en avez plus besoin, demandez à $SUPPORT_CONTACT de le retirer."
