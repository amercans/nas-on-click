# shellcheck shell=bash disable=SC2034,SC1111
# German UI strings. %s placeholders are filled in with noc_fmt.

L_DEFAULT_SUPPORT="Ihre IT-Administration"

L_BTN_OK="OK"
L_BTN_CANCEL="Abbrechen"
L_BTN_RETRY="Erneut versuchen"
L_BTN_START="Starten"
L_BTN_CONNECT="Verbinden"
L_BTN_CONFIRM="Bestätigen"
L_BTN_GOTIT="Verstanden"
L_BTN_LATER="Nicht jetzt"
L_BTN_INSTALL="Installieren"

# Installer
L_INTRO_HEAD="$APP_NAME einrichten"
L_INTRO_REMOTE="Mit dieser Einrichtung öffnen Sie das Büro-NAS sicher – im Büro und von überall sonst. Sie dauert etwa 5 Minuten."
L_INTRO_OFFICE="Mit dieser Einrichtung öffnen Sie das Büro-NAS auf diesem Mac. Sie dauert einige Minuten."
L_INTRO_ASK="Während der Einrichtung werden Sie gefragt nach:"
L_INTRO_ITEM_NAS="• Ihrem NAS-Benutzernamen und Passwort"
L_INTRO_ITEM_MAC="• Ihrem Mac-Passwort (zur Installation der App Cloudflare WARP)"
L_INTRO_ITEM_LOGIN="• einer Anmeldung mit Ihrem $LOGIN_ACCOUNT-Konto"
L_INTRO_TAIL="Nach „Starten“ schließt sich dieses Fenster; die Einrichtung läuft im Hintergrund weiter und öffnet die nötigen Fenster nacheinander. Zeigt macOS die Mitteilung „Hintergrundobjekte hinzugefügt“, lassen Sie sie eingeschaltet – die NAS-Ordner brauchen sie."
L_ALREADY_RUNNING="Die Einrichtung von $APP_NAME läuft bereits. Bitte folgen Sie den geöffneten Fenstern."
L_STATUS_ACCOUNT="Ihr NAS-Konto wird geprüft …"
L_STATUS_WARP="WARP wird verbunden …"
L_STATUS_LAUNCHERS="Die Ordnersymbole werden vorbereitet …"
L_STARTED="Die Einrichtung hat begonnen …"
L_COPY_FAILED="Die Einrichtungsdateien konnten nicht kopiert werden. Kopieren Sie die App auf den Schreibtisch und öffnen Sie sie dort."
L_FAILED_HEAD="Die Einrichtung konnte nicht abgeschlossen werden."
L_FAILED_TAIL="Sie können die Einrichtung erneut starten; abgeschlossene Schritte werden nicht wiederholt. Besteht das Problem weiter, senden Sie ein Bildschirmfoto dieses Fensters an $SUPPORT_CONTACT."
L_UNEXPECTED="Etwas Unerwartetes ist schiefgegangen."
L_CANCELLED="Die Einrichtung wurde abgebrochen."

L_NAS_UNREACHABLE_WARP="Das NAS ist nicht erreichbar. Klicken Sie in der Menüleiste auf das WARP-Symbol und prüfen Sie, dass es verbunden ist (Connected); hat macOS nach einer VPN-Erlaubnis gefragt, wählen Sie „Erlauben“. Starten Sie die Einrichtung dann erneut."
L_NAS_UNREACHABLE_OFFICE="Das NAS ist nicht erreichbar. Diese Einrichtung funktioniert nur im Büronetz; bitte starten Sie sie dort erneut."
L_ENTER_CREDS="Bitte geben Sie im folgenden Fenster Ihren NAS-Benutzernamen und Ihr Passwort ein."
L_ASK_USER="Ihr NAS-Benutzername (z. B. Erika Muster):"
L_USER_EMPTY="Der Benutzername darf nicht leer sein."
L_ASK_PASS="Bitte geben Sie Ihr NAS-Passwort ein:"
L_BAD_CREDS="Benutzername oder Passwort ist falsch. Achten Sie darauf, den Benutzernamen genau wie auf dem NAS zu schreiben, einschließlich Umlauten und Akzenten."
L_RETRY_N="Bitte versuchen Sie es erneut (%s/3)."
L_NO_MORE_TRIES="Drei Versuche sind fehlgeschlagen; die Einrichtung wurde beendet. Bitte prüfen Sie Benutzername und Passwort mit $SUPPORT_CONTACT."
L_CREDS_FAILED_3="Benutzername oder Passwort war dreimal falsch."
L_CONN_PROBLEM="Beim Verbinden mit dem NAS ist ein Problem aufgetreten (Code %s). Warten Sie einige Sekunden und klicken Sie auf „Erneut versuchen“; tritt es weiter auf, wenden Sie sich an $SUPPORT_CONTACT."

L_WARP_FOREIGN="Cloudflare WARP auf diesem Mac wird von einer anderen Organisation verwaltet. Bitte wenden Sie sich an $SUPPORT_CONTACT."
L_WARP_DOWNLOADING="Die Verbindungs-App (Cloudflare WARP) wird geladen, bitte warten."
L_WARP_DL_FAIL="WARP konnte nicht geladen werden. Prüfen Sie Ihre Internetverbindung."
L_WARP_SIG_FAIL="Die Signatur der geladenen Datei konnte nicht bestätigt werden; die Einrichtung wurde beendet."
L_WARP_ADMIN_PROMPT="$APP_NAME benötigt Ihr Mac-Passwort, um die Verbindungs-App (Cloudflare WARP) zu installieren."
L_WARP_CANCELLED="Die Installation von WARP wurde abgebrochen (kein Mac-Passwort eingegeben)."
L_WARP_INSTALL_FAIL="WARP konnte nicht installiert werden. Wurde Ihr Mac-Passwort nicht akzeptiert, sind Sie auf diesem Mac eventuell kein Administrator; wenden Sie sich an $SUPPORT_CONTACT."
L_WARP_INCOMPLETE="Die Installation von WARP wurde nicht abgeschlossen."
L_LOGIN_NOTIFY="Bitte melden Sie sich im Browser mit Ihrem $LOGIN_ACCOUNT-Konto an."
L_LOGIN_DIALOG="Melden Sie sich auf der im Browser geöffneten Seite mit Ihrem $LOGIN_ACCOUNT-Konto an. Danach läuft die Einrichtung von selbst weiter."
L_WARP_SWITCH="Cloudflare WARP auf diesem Mac ist bei einem anderen Konto registriert (%s). Soll es zum Konto von $ORG_NAME wechseln? Die bestehende Registrierung wird entfernt."
L_WARP_PERSONAL="privat"
L_WARP_SWITCH_DECLINED="Abgebrochen; die bestehende WARP-Registrierung wurde nicht geändert."
L_LOGIN_PROGRESS="Schließen Sie die Anmeldung im Browser ab … (Minute %s von 10)"
L_LOGIN_TIMEOUT="Die Anmeldung wurde nicht innerhalb von 10 Minuten abgeschlossen."
L_WARP_NOT_CONNECTED="WICHTIG: WARP ist noch nicht verbunden. Um das NAS außerhalb des Büros zu erreichen, klicken Sie in der Menüleiste auf das WARP-Symbol und verbinden Sie; fragt macOS nach einer VPN-Erlaubnis, wählen Sie „Erlauben“."
L_WARP_SKIPPED_OFFICE="WICHTIG: Die WARP-Einrichtung wurde nicht abgeschlossen. Im Büro funktioniert das NAS; für den Zugriff von unterwegs starten Sie die Einrichtung erneut."
L_WARP_FAILED_OFFICE="WICHTIG: WARP konnte nicht installiert werden. Im Büro funktioniert das NAS; für den Zugriff von unterwegs wenden Sie sich an $SUPPORT_CONTACT."

L_NO_SHARES="Es wurden keine NAS-Ordner gefunden, auf die Sie Zugriff haben. Bitte wenden Sie sich an $SUPPORT_CONTACT."
L_AGENT_NOT_RUNNING="Der Hintergrunddienst von $APP_NAME läuft nicht. Erlauben Sie ihn unter Systemeinstellungen > Allgemein > Anmeldeobjekte oder führen Sie die Einrichtung von $APP_NAME erneut aus."
L_LOC_DESKTOP="Ihre NAS-Ordner liegen im Ordner „$FOLDER_NAME“ auf dem Schreibtisch."
L_LOC_HOME="Ihre NAS-Ordner liegen im Ordner „$FOLDER_NAME“ in Ihrem Benutzerordner (Finder > Gehe zu > Benutzerordner)."
L_FINAL_TITLE="ACHTUNG: DATEIEN UND ORDNER, DIE SIE IN NAS-ORDNERN LÖSCHEN, WERDEN AUF DEM NAS GELÖSCHT, NICHT NUR AUF IHREM MAC."
L_FINAL_DONE="Die Einrichtung ist abgeschlossen."
L_FINAL_HOWTO="Doppelklicken Sie auf ein Ordnersymbol, um ihn zu öffnen; der Ordner erscheint nach wenigen Sekunden im Finder."
L_FINAL_WHERE="Die Dateien in einem geöffneten Ordner liegen auf dem NAS, nicht auf Ihrem Mac; jede Änderung und jedes Löschen wirkt direkt auf dem NAS."
L_FINAL_SIDEBAR="Tipp: Ziehen Sie den Ordner „$FOLDER_NAME“ in der Finder-Seitenleiste unter „Favoriten“, dann sind Ihre NAS-Ordner immer einen Klick entfernt."
L_FINAL_WARP="Achten Sie außerhalb des Büros darauf, dass die WARP-App in der Menüleiste verbunden ist."

# Background task
L_SETUP_INCOMPLETE="Die Einrichtung von $APP_NAME ist nicht abgeschlossen. Bitte führen Sie sie erneut aus."
L_UNREACHABLE_WARP="Das NAS ist nicht erreichbar.

Wenn Sie nicht im Büro sind, klicken Sie in der Menüleiste auf das WARP-Symbol und prüfen Sie, dass es verbunden ist (Connected). Fragt WARP nach einer Anmeldung, melden Sie sich erneut mit Ihrem $LOGIN_ACCOUNT-Konto an. Klicken Sie dann erneut auf den Ordner."
L_UNREACHABLE_NOWARP="Das NAS ist nicht erreichbar.

Cloudflare WARP auf diesem Mac ist nicht beim Konto von $ORG_NAME registriert. Bitte führen Sie die Einrichtung von $APP_NAME erneut aus oder wenden Sie sich an $SUPPORT_CONTACT."
L_UNREACHABLE_OFFICE="Das NAS ist nicht erreichbar. NAS-Ordner lassen sich nur im Büronetz öffnen."
L_NO_PASSWORD="Das NAS-Passwort wurde nicht gefunden. Bitte führen Sie die Einrichtung erneut aus."
L_PW_CHANGED="Ihr NAS-Passwort scheint sich geändert zu haben.

Kennen Sie Ihr neues Passwort nicht, erfragen Sie es bei $SUPPORT_CONTACT und geben Sie es unten ein."
L_PW_REJECTED="Das eingegebene Passwort wurde nicht akzeptiert. Bitte prüfen Sie es mit $SUPPORT_CONTACT und klicken Sie erneut auf den Ordner."
L_OLD_MOUNT_BUSY="Die alte Verbindung von „%s“ konnte nicht getrennt werden (eventuell ist eine Datei geöffnet). Schließen Sie geöffnete Dateien und versuchen Sie es erneut."
L_OPEN_FAILED="„%s“ konnte nicht geöffnet werden. Versuchen Sie es in einigen Sekunden erneut; tritt es weiter auf, wenden Sie sich an $SUPPORT_CONTACT."

# Updates
L_UPDATE_AVAILABLE="Eine neue Version von $APP_NAME ist verfügbar (%s).

%s

Jetzt installieren? Das dauert wenige Sekunden und betrifft geöffnete NAS-Ordner nicht."
L_UPDATE_DONE="$APP_NAME wurde auf Version %s aktualisiert."
L_UPDATE_FAILED="Das Update von $APP_NAME konnte nicht installiert werden; die aktuelle Version bleibt in Gebrauch."

# Repair / uninstall (setup app opened again)
L_BTN_REPAIR="Reparieren"
L_BTN_UNINSTALL="Deinstallieren"
L_INSTALLED_CHOICE="$APP_NAME ist auf diesem Mac bereits installiert. Möchten Sie es reparieren oder deinstallieren?"
L_UNINSTALL_CONFIRM="$APP_NAME deinstallieren? Die Ordnersymbole, der Hintergrunddienst und das auf diesem Mac gespeicherte NAS-Passwort werden entfernt. Dateien auf dem NAS bleiben unberührt. Cloudflare WARP bleibt installiert."
L_UNINSTALL_BUSY="Einige NAS-Ordner konnten nicht getrennt werden, weil Dateien darauf geöffnet sind. Schließen Sie diese Dateien und versuchen Sie es erneut. Es wurde nichts entfernt."
L_UNINSTALL_DONE="$APP_NAME wurde von diesem Mac entfernt. Cloudflare WARP ist weiterhin installiert; brauchen Sie es nicht mehr, bitten Sie $SUPPORT_CONTACT, es zu entfernen."
