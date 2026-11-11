# shellcheck shell=bash disable=SC2034,SC1111
# Turkish UI strings. %s placeholders are filled in with printf.

L_DEFAULT_SUPPORT="sistem yöneticiniz"

L_BTN_OK="Tamam"
L_BTN_CANCEL="Vazgeç"
L_BTN_RETRY="Tekrar Dene"
L_BTN_START="Başla"
L_BTN_CONNECT="Bağlan"
L_BTN_CONFIRM="Onayla"
L_BTN_GOTIT="Anladım"
L_BTN_LATER="Şimdi değil"
L_BTN_INSTALL="Kur"

# Installer
L_INTRO_HEAD="$APP_NAME Kurulumu"
L_INTRO_REMOTE="Bu kurulum, ofis NAS'ına ofis dışından da güvenli ve hızlı erişebilmeniz için gerekli ayarları yapar. İşlem yaklaşık 5 dakika sürer."
L_INTRO_OFFICE="Bu kurulum, ofis NAS'ına erişebilmeniz için gerekli ayarları yapar. İşlem birkaç dakika sürer."
L_INTRO_ASK="Kurulum sırasında sizden şunlar istenecektir:"
L_INTRO_ITEM_NAS="• NAS kullanıcı adınız ve şifreniz"
L_INTRO_ITEM_MAC="• Mac şifreniz (bağlantı uygulaması WARP'ın kurulumu için)"
L_INTRO_ITEM_LOGIN="• $LOGIN_ACCOUNT hesabınızla giriş"
L_INTRO_TAIL="Başla'ya bastıktan sonra bu pencere kapanır; kurulum arka planda sürer, gereken pencereler sırayla açılır. macOS “Arka plan öğesi eklendi” bildirimi gösterirse kapatmayın; NAS klasörlerinin çalışması bunu kullanır."
L_ALREADY_RUNNING="$APP_NAME kurulumu zaten devam ediyor. Lütfen açık pencereleri takip edin."
L_NOTIFY_TITLE="$APP_NAME kurulumu"
L_STARTED="Kurulum başladı. İlerleme bildirimleriyle haberdar olacaksınız."
L_COPY_FAILED="Kurulum dosyaları kopyalanamadı. Uygulamayı Masaüstüne kopyalayıp oradan açın."
L_FAILED_HEAD="Kurulum tamamlanamadı."
L_FAILED_TAIL="Kurulumu yeniden başlatabilirsiniz; tamamlanan adımlar tekrarlanmaz. Sorun sürerse bu pencerenin ekran görüntüsünü $SUPPORT_CONTACT ile paylaşın."
L_UNEXPECTED="Beklenmeyen bir sorun oluştu."
L_CANCELLED="Kurulum iptal edildi."

L_NAS_UNREACHABLE_WARP="NAS’a ulaşılamadı. Menü çubuğundaki WARP simgesine tıklayıp bağlı (Connected) olduğundan emin olun; macOS bir VPN izni sorduysa İzin Ver'e basın. Ardından kurulumu yeniden başlatın."
L_NAS_UNREACHABLE_OFFICE="NAS’a ulaşılamadı. Bu kurulum yalnızca ofis ağında çalışır; lütfen ofis ağına bağlıyken yeniden başlatın."
L_ENTER_CREDS="Lütfen açılan pencereye NAS kullanıcı adınızı ve şifrenizi girin."
L_ASK_USER="NAS kullanıcı adınız (örnek: Ayşe Yılmaz):"
L_USER_EMPTY="Kullanıcı adı boş bırakılamaz."
L_ASK_PASS="Lütfen NAS şifrenizi girin:"
L_BAD_CREDS="Kullanıcı adı veya şifre hatalı. Kullanıcı adının Türkçe harfleriyle (ğ, ü, ş, ı, ö, ç) yazıldığından emin olun."
L_RETRY_N="Lütfen tekrar deneyin (%s/3)."
L_NO_MORE_TRIES="3 deneme hakkı doldu; kurulum durduruldu. Lütfen kullanıcı adınızı ve şifrenizi $SUPPORT_CONTACT ile kontrol edin."
L_CREDS_FAILED_3="Kullanıcı adı veya şifre 3 kez hatalı."
L_CONN_PROBLEM="NAS'a bağlanırken bir sorun oluştu (kod %s). Şifreniz denenmedi. Lütfen birkaç saniye sonra Tekrar Dene'ye basın; sorun sürerse $SUPPORT_CONTACT ile iletişime geçin."

L_WARP_FOREIGN="Bu Mac'teki WARP başka bir kurum tarafından yönetiliyor. Lütfen $SUPPORT_CONTACT ile iletişime geçin."
L_WARP_DOWNLOADING="Bağlantı uygulaması (Cloudflare WARP) indiriliyor, lütfen bekleyin."
L_WARP_DL_FAIL="WARP indirilemedi. İnternet bağlantınızı kontrol edin."
L_WARP_SIG_FAIL="İndirilen dosyanın imzası doğrulanamadı, kurulum durduruldu."
L_WARP_ADMIN_PROMPT="$APP_NAME, bağlantı uygulamasını (Cloudflare WARP) kurmak için Mac şifrenizi istiyor."
L_WARP_CANCELLED="WARP kurulumu iptal edildi (Mac şifresi girilmedi)."
L_WARP_INSTALL_FAIL="WARP kurulamadı. Mac şifresi kabul edilmediyse bu bilgisayarda yönetici olmayabilirsiniz; $SUPPORT_CONTACT ile iletişime geçin."
L_WARP_INCOMPLETE="WARP kurulumu tamamlanamadı."
L_LOGIN_NOTIFY="Lütfen tarayıcıda $LOGIN_ACCOUNT hesabınızla giriş yapın."
L_LOGIN_DIALOG="Tarayıcıda açılan sayfada $LOGIN_ACCOUNT hesabınızla giriş yapın. Giriş tamamlanınca kurulum kendiliğinden devam eder."
L_WARP_SWITCH="Bu Mac’teki WARP uygulaması başka bir hesaba kayıtlı (%s). $ORG_NAME hesabına geçirilmesini onaylıyor musunuz? Mevcut kayıt kaldırılacaktır."
L_WARP_PERSONAL="kişisel"
L_WARP_SWITCH_DECLINED="İşlem iptal edildi; mevcut WARP kaydı değiştirilmedi."
L_LOGIN_PROGRESS="Tarayıcıda girişi tamamlayın... (%s. dakika / 10)"
L_LOGIN_TIMEOUT="Giriş 10 dakika içinde tamamlanmadı."
L_WARP_NOT_CONNECTED="ÖNEMLİ: WARP henüz bağlı değil. Ofis dışından erişim için menü çubuğundaki WARP simgesine tıklayıp bağlanın; macOS bir VPN izni sorarsa İzin Ver'e basın."
L_WARP_SKIPPED_OFFICE="ÖNEMLİ: WARP kurulumu tamamlanmadı. Ofiste NAS'a erişebilirsiniz; ofis dışından erişim için kurulumu yeniden çalıştırın."
L_WARP_FAILED_OFFICE="ÖNEMLİ: WARP kurulamadı. Ofiste NAS'a erişebilirsiniz, ancak ofis dışından erişim için $SUPPORT_CONTACT ile iletişime geçin."

L_NO_SHARES="Erişiminiz olan NAS klasörü bulunamadı. Lütfen $SUPPORT_CONTACT ile iletişime geçin."
L_AGENT_NOT_RUNNING="$APP_NAME arka plan görevi çalışmıyor. Sistem Ayarları > Genel > Giriş Öğeleri bölümünde arka planda çalışma izinlerini açın veya $APP_NAME kurulumunu yeniden çalıştırın."
L_LOC_DESKTOP="NAS klasörleriniz masaüstündeki \"$FOLDER_NAME\" klasöründedir."
L_LOC_HOME="NAS klasörleriniz ev klasörünüzdeki \"$FOLDER_NAME\" klasöründedir (Finder > Git > Ana Klasör)."
L_FINAL_TITLE="DİKKAT: NAS KLASÖRLERİNDE SİLDİĞİNİZ DOSYA VE KLASÖRLER KENDİ BİLGİSAYARINIZDAN DEĞİL, NAS'TAN SİLİNİR."
L_FINAL_DONE="Kurulum tamamlandı."
L_FINAL_HOWTO="Bir klasörü açmak için simgesine çift tıklayın; klasör birkaç saniye içinde Finder'da açılır."
L_FINAL_WHERE="Açılan klasördeki dosyalar bilgisayarınızda değil, NAS'ta durur; yapılan her değişiklik ve silme işlemi doğrudan NAS'a uygulanır."
L_FINAL_WARP="Ofis dışındayken menü çubuğundaki WARP uygulamasının bağlı olduğundan emin olun."

# Background task
L_SETUP_INCOMPLETE="$APP_NAME kurulumu tamamlanmamış. Lütfen kurulumu yeniden çalıştırın."
L_UNREACHABLE_WARP="NAS'a ulaşılamıyor.

Ofis dışındaysanız menü çubuğundaki WARP simgesine tıklayıp bağlı (Connected) olduğundan emin olun. WARP giriş istiyorsa $LOGIN_ACCOUNT hesabınızla yeniden giriş yapın. Ardından klasöre yeniden tıklayın."
L_UNREACHABLE_NOWARP="NAS'a ulaşılamıyor.

Bu Mac'teki WARP uygulaması $ORG_NAME hesabına bağlı değil. Lütfen $APP_NAME kurulumunu yeniden çalıştırın veya $SUPPORT_CONTACT ile iletişime geçin."
L_UNREACHABLE_OFFICE="NAS'a ulaşılamıyor. NAS klasörleri yalnızca ofis ağındayken açılabilir."
L_NO_PASSWORD="NAS şifresi bulunamadı. Lütfen kurulumu yeniden çalıştırın."
L_PW_CHANGED="NAS şifreniz değişmiş görünüyor.

Yeni şifrenizi bilmiyorsanız veya unuttuysanız lütfen $SUPPORT_CONTACT ile iletişime geçip yeni şifre talep edin ve aşağıya girin."
L_PW_REJECTED="Girdiğiniz şifre kabul edilmedi. Lütfen şifrenizi $SUPPORT_CONTACT ile kontrol edin ve klasöre yeniden tıklayın."
L_OLD_MOUNT_BUSY="\"%s\" klasörünün eski bağlantısı kapatılamadı (açık dosya olabilir). Açık dosyaları kapatıp yeniden deneyin."
L_OPEN_FAILED="\"%s\" klasörü açılamadı. Birkaç saniye sonra yeniden deneyin; sorun sürerse $SUPPORT_CONTACT ile iletişime geçin."

# Updates
L_UPDATE_AVAILABLE="$APP_NAME için yeni bir sürüm var (%s).

%s

Şimdi kurulsun mu? Kurulum birkaç saniye sürer; açık NAS klasörleriniz etkilenmez."
L_UPDATE_DONE="$APP_NAME %s sürümüne güncellendi."
L_UPDATE_FAILED="$APP_NAME güncellemesi kurulamadı; mevcut sürüm kullanılmaya devam ediyor."
