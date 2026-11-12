# shellcheck shell=bash disable=SC2034,SC1111
# Spanish UI strings. %s placeholders are filled in with noc_fmt.

L_DEFAULT_SUPPORT="su administrador"

L_BTN_OK="Aceptar"
L_BTN_CANCEL="Cancelar"
L_BTN_RETRY="Reintentar"
L_BTN_START="Empezar"
L_BTN_CONNECT="Conectar"
L_BTN_CONFIRM="Confirmar"
L_BTN_GOTIT="Entendido"
L_BTN_LATER="Ahora no"
L_BTN_INSTALL="Instalar"

# Installer
L_INTRO_HEAD="Instalación de $APP_NAME"
L_INTRO_REMOTE="Esta instalación le permite abrir el NAS de la oficina de forma segura, tanto en la oficina como desde cualquier otro lugar. Tarda unos 5 minutos."
L_INTRO_OFFICE="Esta instalación le permite abrir el NAS de la oficina desde este Mac. Tarda unos minutos."
L_INTRO_ASK="Durante la instalación se le pedirá:"
L_INTRO_ITEM_NAS="• su nombre de usuario y contraseña del NAS"
L_INTRO_ITEM_MAC="• la contraseña de su Mac (para instalar la app Cloudflare WARP)"
L_INTRO_ITEM_LOGIN="• iniciar sesión con su cuenta de $LOGIN_ACCOUNT"
L_INTRO_TAIL="Al pulsar «Empezar», esta ventana se cierra; la instalación continúa en segundo plano y abre las ventanas necesarias una tras otra. Si macOS muestra el aviso «Ítems en segundo plano añadidos», déjelo activado: las carpetas del NAS lo necesitan."
L_ALREADY_RUNNING="La instalación de $APP_NAME ya está en marcha. Siga las ventanas abiertas."
L_STATUS_ACCOUNT="Comprobando su cuenta del NAS…"
L_STATUS_WARP="Conectando WARP…"
L_STATUS_LAUNCHERS="Preparando los iconos de las carpetas…"
L_STARTED="La instalación ha comenzado…"
L_COPY_FAILED="No se pudieron copiar los archivos de instalación. Copie la app al Escritorio y ábrala desde allí."
L_FAILED_HEAD="La instalación no se pudo completar."
L_FAILED_TAIL="Puede volver a iniciar la instalación; los pasos terminados no se repiten. Si el problema continúa, envíe una captura de esta ventana a $SUPPORT_CONTACT."
L_UNEXPECTED="Ha ocurrido un error inesperado."
L_CANCELLED="La instalación se ha cancelado."

L_NAS_UNREACHABLE_WARP="No se puede acceder al NAS. Haga clic en el icono de WARP de la barra de menús y compruebe que está conectado (Connected); si macOS pidió permiso para una VPN, elija «Permitir». Después vuelva a iniciar la instalación."
L_NAS_UNREACHABLE_OFFICE="No se puede acceder al NAS. Esta instalación solo funciona en la red de la oficina; vuelva a ejecutarla conectado a ella."
L_ENTER_CREDS="Escriba su nombre de usuario y contraseña del NAS en la ventana que se abre."
L_ASK_USER="Su nombre de usuario del NAS (p. ej., Ana García):"
L_USER_EMPTY="El nombre de usuario no puede estar vacío."
L_ASK_PASS="Escriba su contraseña del NAS:"
L_BAD_CREDS="El nombre de usuario o la contraseña no son correctos. Compruebe que el nombre de usuario está escrito exactamente como en el NAS, con tildes incluidas."
L_RETRY_N="Inténtelo de nuevo (%s/3)."
L_NO_MORE_TRIES="Han fallado tres intentos y la instalación se ha detenido. Compruebe su nombre de usuario y contraseña con $SUPPORT_CONTACT."
L_CREDS_FAILED_3="El nombre de usuario o la contraseña fueron incorrectos tres veces."
L_CONN_PROBLEM="Hubo un problema al conectar con el NAS (código %s). Espere unos segundos y pulse «Reintentar»; si vuelve a ocurrir, contacte con $SUPPORT_CONTACT."

L_WARP_FOREIGN="Cloudflare WARP en este Mac lo gestiona otra organización. Contacte con $SUPPORT_CONTACT."
L_WARP_DOWNLOADING="Descargando la app de conexión (Cloudflare WARP), espere un momento."
L_WARP_DL_FAIL="No se pudo descargar WARP. Compruebe su conexión a Internet."
L_WARP_SIG_FAIL="No se pudo verificar la firma del archivo descargado; la instalación se ha detenido."
L_WARP_ADMIN_PROMPT="$APP_NAME necesita la contraseña de su Mac para instalar la app de conexión (Cloudflare WARP)."
L_WARP_CANCELLED="Se canceló la instalación de WARP (no se introdujo la contraseña del Mac)."
L_WARP_INSTALL_FAIL="No se pudo instalar WARP. Si no se aceptó la contraseña de su Mac, puede que no sea administrador de este Mac; contacte con $SUPPORT_CONTACT."
L_WARP_INCOMPLETE="La instalación de WARP no terminó."
L_LOGIN_NOTIFY="Inicie sesión en el navegador con su cuenta de $LOGIN_ACCOUNT."
L_LOGIN_DIALOG="Inicie sesión con su cuenta de $LOGIN_ACCOUNT en la página que se abrió en su navegador. La instalación continuará sola cuando termine."
L_WARP_SWITCH="Cloudflare WARP en este Mac está registrado en otra cuenta (%s). ¿Quiere pasarlo a la cuenta de $ORG_NAME? Se eliminará el registro actual."
L_WARP_PERSONAL="personal"
L_WARP_SWITCH_DECLINED="Cancelado; el registro actual de WARP no se ha modificado."
L_LOGIN_PROGRESS="Termine de iniciar sesión en el navegador… (minuto %s de 10)"
L_LOGIN_TIMEOUT="No se completó el inicio de sesión en 10 minutos."
L_WARP_NOT_CONNECTED="IMPORTANTE: WARP aún no está conectado. Para acceder al NAS fuera de la oficina, haga clic en el icono de WARP de la barra de menús y conéctese; si macOS pide permiso para una VPN, elija «Permitir»."
L_WARP_SKIPPED_OFFICE="IMPORTANTE: la configuración de WARP no se completó. El NAS funciona en la oficina; vuelva a ejecutar la instalación para acceder desde otros lugares."
L_WARP_FAILED_OFFICE="IMPORTANTE: no se pudo instalar WARP. El NAS funciona en la oficina; para acceder desde otros lugares, contacte con $SUPPORT_CONTACT."

L_NO_SHARES="No se encontraron carpetas del NAS a las que tenga acceso. Contacte con $SUPPORT_CONTACT."
L_AGENT_NOT_RUNNING="La tarea en segundo plano de $APP_NAME no se está ejecutando. Permítala en Ajustes del Sistema > General > Ítems de inicio, o vuelva a ejecutar la instalación de $APP_NAME."
L_LOC_DESKTOP="Sus carpetas del NAS están en la carpeta «$FOLDER_NAME» del Escritorio."
L_LOC_HOME="Sus carpetas del NAS están en la carpeta «$FOLDER_NAME» de su carpeta de inicio (Finder > Ir > Inicio)."
L_FINAL_TITLE="ATENCIÓN: LOS ARCHIVOS Y CARPETAS QUE ELIMINE EN LAS CARPETAS DEL NAS SE ELIMINAN DEL NAS, NO SOLO DE SU MAC."
L_FINAL_DONE="La instalación ha terminado."
L_FINAL_HOWTO="Haga doble clic en el icono de una carpeta para abrirla; la carpeta se abre en el Finder en unos segundos."
L_FINAL_WHERE="Los archivos de una carpeta abierta están en el NAS, no en su Mac; cada cambio y cada eliminación se aplica directamente en el NAS."
L_FINAL_SIDEBAR="Consejo: arrastre la carpeta «$FOLDER_NAME» a Favoritos en la barra lateral del Finder para tener sus carpetas del NAS a un clic."
L_FINAL_WARP="Fuera de la oficina, compruebe que la app WARP de la barra de menús está conectada."

# Background task
L_SETUP_INCOMPLETE="La instalación de $APP_NAME no está completa. Vuelva a ejecutarla."
L_UNREACHABLE_WARP="No se puede acceder al NAS.

Si no está en la oficina, haga clic en el icono de WARP de la barra de menús y compruebe que está conectado (Connected). Si WARP le pide iniciar sesión, vuelva a hacerlo con su cuenta de $LOGIN_ACCOUNT. Después haga clic de nuevo en la carpeta."
L_UNREACHABLE_NOWARP="No se puede acceder al NAS.

Cloudflare WARP en este Mac no está registrado en la cuenta de $ORG_NAME. Vuelva a ejecutar la instalación de $APP_NAME o contacte con $SUPPORT_CONTACT."
L_UNREACHABLE_OFFICE="No se puede acceder al NAS. Las carpetas del NAS solo se abren en la red de la oficina."
L_NO_PASSWORD="No se encontró la contraseña del NAS. Vuelva a ejecutar la instalación."
L_PW_CHANGED="Parece que su contraseña del NAS ha cambiado.

Si no conoce la nueva, pídasela a $SUPPORT_CONTACT y escríbala abajo."
L_PW_REJECTED="La contraseña introducida no fue aceptada. Compruébela con $SUPPORT_CONTACT y vuelva a hacer clic en la carpeta."
L_OLD_MOUNT_BUSY="No se pudo cerrar la conexión anterior de «%s» (puede que haya un archivo abierto). Cierre los archivos abiertos y vuelva a intentarlo."
L_OPEN_FAILED="No se pudo abrir «%s». Vuelva a intentarlo en unos segundos; si sigue ocurriendo, contacte con $SUPPORT_CONTACT."

# Updates
L_UPDATE_AVAILABLE="Hay una nueva versión de $APP_NAME (%s).

%s

¿Instalarla ahora? Tarda unos segundos y no afecta a las carpetas del NAS abiertas."
L_UPDATE_DONE="$APP_NAME se actualizó a la versión %s."
L_UPDATE_FAILED="No se pudo instalar la actualización de $APP_NAME; se sigue usando la versión actual."

# Repair / uninstall (setup app opened again)
L_BTN_REPAIR="Reparar"
L_BTN_UNINSTALL="Desinstalar"
L_INSTALLED_CHOICE="$APP_NAME ya está instalado en este Mac. ¿Quiere repararlo o desinstalarlo?"
L_UNINSTALL_CONFIRM="¿Desinstalar $APP_NAME? Se eliminan los iconos de las carpetas, la tarea en segundo plano y la contraseña del NAS guardada en este Mac. Los archivos del NAS no se tocan. Cloudflare WARP sigue instalado."
L_UNINSTALL_BUSY="Algunas carpetas del NAS no se pudieron cerrar porque tienen archivos abiertos. Cierre esos archivos y vuelva a intentarlo. No se ha eliminado nada."
L_UNINSTALL_DONE="$APP_NAME se ha eliminado de este Mac. Cloudflare WARP sigue instalado; si ya no lo necesita, pida a $SUPPORT_CONTACT que lo quite."
