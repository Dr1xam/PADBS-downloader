#!/bin/bash
#дерикторія в яку завантажиться інсталятор
#DOWNLOAD_DIR="/var/lib/vz/snippets"
DOWNLOAD_DIR="./test"
#Дерикторія прграми порсингу силок
VERSION_DEFINDER_DIR="./src/python/version_definder"
#Назва архіву з кодом програми
PROGRAM_ARCHIVE_NAME="PADBS.tar.gz"
#Розташування архівованих інсталяторів програм
TAR_GZ_DIR="./resources/software/tar-gz"
#Розташування хмарних образів
CLOUD_IMAGES_DIR="./resources/software/cloud-images"
#Розташування ісо
ISO_DIR="./resources/software/iso"
#Розташування розархівованих інсталяторів програм
SOFTWARE_DIR="./resources/software"
#Розташування програми пошуку посилань
VERSION_DEFINDER_DIR="./src/python/version-definder"

# Перевірка whiptail
if ! command -v whiptail &> /dev/null; then
    echo "Встановлення whiptail для графічного інтерфейсу"
    apt-get update -qq && apt-get install -y -qq whiptail
fi

if ! command -v aria2c &> /dev/null; then
    echo "Встановлення aria2 для багатопотокового завантаження"
    apt-get update -qq && apt-get install -y -qq aria2
fi
#Завантаження архіву з коом програми
aria2c -d "$DOWNLOAD_DIR" -x 16 -o "$PROGRAM_ARCHIVE_NAME" https://github.com/Dr1xam/PADBS-installer/archive/refs/tags/v0.1.1.tar.gz
#Переходимо в директорію з програмою
cd "$DOWNLOAD_DIR"

# 1. Визначаємо назву кореневої папки, не розпаковуючи
# (беремо список файлів -> перший рядок -> відрізаємо все після першого слеша)
DIR_NAME=$(tar -tf "$PROGRAM_ARCHIVE_NAME" | head -1 | cut -d/ -f1)

# 2. Розпаковуємо
tar -xzvf "$PROGRAM_ARCHIVE_NAME"
#Видалямо архів
rm "$PROGRAM_ARCHIVE_NAME"
# 3. Перевіряємо, чи це справді папка, і заходимо в програму
    cd "$DIR_NAME"
#створення директорій в програмі
mkdir "./resources"
mkdir "./resources/cloud-images"
mkdir "./resources/iso"
mkdir "$SOFTWARE_DIR"
mkdir "$TAR_GZ_DIR"
#Створюєм директрію з інсталяційними файлами піпу
mkdir "$SOFTWARE_DIR/pip"
#Завантажуємо скрипт для встановлення піпу онлайн
python3 -c "import urllib.request; urllib.request.urlretrieve('https://bootstrap.pypa.io/get-pip.py', '$SOFTWARE_DIR/pip/get-pip.py')"
#Завантажуємо інсталяційні файли і залежності піпу
python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/pip/json'; data=json.load(urllib.request.urlopen(url)); f=next(x for x in data['urls'] if x['filename'].endswith('.whl')); print(f'Downloading {f['filename']}...'); full_path=os.path.join(path, f['filename']); urllib.request.urlretrieve(f['url'], full_path); print(f'Saved to: {os.path.abspath(full_path)}')"
python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/setuptools/json'; data=json.load(urllib.request.urlopen(url)); f=[x for x in data['urls'] if x['filename'].endswith('.whl')][0]; print('Downloading ' + f['filename']); urllib.request.urlretrieve(f['url'], os.path.join(path, f['filename'])); print('Saved to ' + path)"
python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/wheel/json'; data=json.load(urllib.request.urlopen(url)); f=[x for x in data['urls'] if x['filename'].endswith('.whl')][0]; print('Downloading ' + f['filename']); urllib.request.urlretrieve(f['url'], os.path.join(path, f['filename'])); print('Saved to ' + path)"
#Створюєм директрію з інсталяційними файлами ансібла
mkdir -p "$SOFTWARE_DIR/ansible"
#Завантажуємо інсталяційні файли енсібла
pip download ansible --dest $SOFTWARE_DIR/ansible/
# Завантаження в багато потоків
# Створення тимчасових файлів
TMP_UBUNTU=$(mktemp)
TMP_ROCKET=$(mktemp)
TMP_ZABBIX=$(mktemp)
TMP_DEBIAN=$(mktemp)
TMP_PEX_MGR=$(mktemp)
TMP_PEX_CONF=$(mktemp)

# Запускаємо Python-парсери у фоні
{
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" ubuntu > "$TMP_UBUNTU" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" rocketchat > "$TMP_ROCKET" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" zabbix > "$TMP_ZABBIX" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" debian > "$TMP_DEBIAN" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" pexip_manage > "$TMP_PEX_MGR" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" pexip_conf > "$TMP_PEX_CONF" &
    wait
} | whiptail --gauge "Отримання списків версій для всіх програм..." 6 60 0

# Оголошення асоціативних масивів для лінків
declare -A MAP_UBUNTU
declare -A MAP_ROCKET
declare -A MAP_ZABBIX
declare -A MAP_DEBIAN
declare -A MAP_PEX_MGR
declare -A MAP_PEX_CONF
# Оголошення масивів для меню
MENU_UBUNTU=()
MENU_ROCKET=()
MENU_ZABBIX=()
MENU_DEBIAN=()
MENU_PEX_MGR=()
MENU_PEX_CONF=()
# Функція читання файлу у змінні
load_data() {
    local file="$1"
    declare -n menu_ref="$2"
    declare -n map_ref="$3"

    # Якщо файл порожній або помилка парсингу
    if [ ! -s "$file" ]; then
        return
    fi

    while read -r VER LINK; do
        if [[ -n "$VER" ]]; then
            menu_ref+=("$VER" "" "OFF")
            map_ref["$VER"]="$LINK"
        fi
    done < "$file"
}

load_data "$TMP_UBUNTU"   MENU_UBUNTU   MAP_UBUNTU
load_data "$TMP_ROCKET"   MENU_ROCKET   MAP_ROCKET
load_data "$TMP_ZABBIX"   MENU_ZABBIX   MAP_ZABBIX
load_data "$TMP_DEBIAN"   MENU_DEBIAN   MAP_DEBIAN
load_data "$TMP_PEX_MGR"  MENU_PEX_MGR  MAP_PEX_MGR
load_data "$TMP_PEX_CONF" MENU_PEX_CONF MAP_PEX_CONF
# Видаляємо тимчасові файли
rm "$TMP_UBUNTU" "$TMP_ROCKET" "$TMP_ZABBIX" "$TMP_DEBIAN" "$TMP_PEX_MGR" "$TMP_PEX_CONF"
#Вибір програм(Меню (головне))
while true; do
    RAW_APPS=$(whiptail --title "Менеджер завантажень" --checklist \
    "Які продукти ви хочете завантажити?" 20 56 5 \
    "RocketChat"  "Rocket.Chat Server (+ Ubuntu Base)" ON \
    "Zabbix"      "Zabbix Appliance (.ovf)" ON \
    "Debian"      "Debian Cloud Image (.qcow2)" ON \
    "Pexip_Mgr"   "Pexip Management Node (.ova)" ON \
    "Pexip_Conf"  "Pexip Conferencing Node (.ova)" ON \
    3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        echo "Роботу завершено користувачем."
        exit 0
    fi

    if [ -n "$RAW_APPS" ]; then
        break
    else
        whiptail --title "Увага" --msgbox "Ви нічого не вибрали!\nБудь ласка, оберіть хоча б один пункт." 8 56
    fi
done

SELECTED_APPS_STR=$(echo $RAW_APPS | tr -d '"')
#Вибір версій (меню)
# Універсальна функція вибору
safe_select() {
    local title="$1"
    local text="$2"
    declare -n menu_opts="$3"
    local result_var="$4"
    local selection=""

    # Перевірка, чи є взагалі версії для вибору
    if [ ${#menu_opts[@]} -eq 0 ]; then
        whiptail --title "Помилка" --msgbox "Не знайдено доступних версій для $title.\nПеревірте інтернет або логи парсера." 10 56
        eval "$result_var=\"ERROR\""
        return
    fi

    while true; do
        selection=$(whiptail --title "$title" --radiolist \
        "$text" 20 56 13 \
        "${menu_opts[@]}" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            echo "Вихід під час вибору версії."
            exit 0
        fi

        if [ -n "$selection" ]; then
            break
        else
            whiptail --msgbox "Необхідно вибрати версію зі списку!" 8 40
        fi
    done

    eval "$result_var=\"$selection\""
}

# --- ROCKET CHAT (залежить від Ubuntu) ---
if [[ "$SELECTED_APPS_STR" == *"RocketChat"* ]]; then
    # Автоматичний вибір останньої (першої в списку) версії Ubuntu
    if [ ${#MENU_UBUNTU[@]} -gt 0 ]; then
        # У MENU_UBUNTU структура: [VER, "", "OFF", VER, "", "OFF"...]
        # Тому перший елемент (індекс 0) - це найновіша версія (за умови сортування парсером)
        VER_UBUNTU="${MENU_UBUNTU[0]}"
        echo "Автоматично обрано Ubuntu Base: $VER_UBUNTU"
    else
        VER_UBUNTU="ERROR"
        whiptail --msgbox "Не вдалося автоматично визначити версію Ubuntu!" 8 52
        #Придумай що робити з помилкою !!!!!!!!!!!!!!!!!!!!!!!1
    fi

    # Для самого RocketChat залишаємо ручний вибір
    safe_select "RocketChat -> Application" "Оберіть версію RocketChat:" MENU_ROCKET VER_ROCKET
fi

# --- ZABBIX ---
if [[ "$SELECTED_APPS_STR" == *"Zabbix"* ]]; then
    safe_select "Zabbix Appliance" "Оберіть версію Zabbix:" MENU_ZABBIX VER_ZABBIX
fi

# --- DEBIAN ---
if [[ "$SELECTED_APPS_STR" == *"Debian"* ]]; then
    safe_select "Debian Cloud" "Оберіть версію Debian (Backports):" MENU_DEBIAN VER_DEBIAN
fi

# --- PEXIP ---
LATEST_COMMON_VER=""

if [[ "$SELECTED_APPS_STR" == *"Pexip_Mgr"* ]] || [[ "$SELECTED_APPS_STR" == *"Pexip_Conf"* ]]; then

    # 1. Перевіряємо, чи масиви не порожні
    if [ ${#MENU_PEX_MGR[@]} -eq 0 ] || [ ${#MENU_PEX_CONF[@]} -eq 0 ]; then
        echo "Помилка: Не вдалося отримати списки версій для порівняння."
        exit 1
    fi

    # 2. Алгоритм пошуку спільної версії
    # Проходимо по версіях Manager (від найновішої)
    for ver_mgr in "${MENU_PEX_MGR[@]}"; do
        # Для кожної версії Manager перевіряємо, чи є вона в списку ConfNode
        for ver_conf in "${MENU_PEX_CONF[@]}"; do
            if [[ "$ver_mgr" == "$ver_conf" ]]; then
                LATEST_COMMON_VER="$ver_mgr"
                break 2 # Знайшли спільну! Виходимо з обох циклів
            fi
        done
    done

    # 3. Перевірка результату
    if [[ -z "$LATEST_COMMON_VER" ]]; then
        echo "Критична помилка: Не знайдено жодної спільної версії між Pexip Manager та ConfNode!"
        exit 1
    else
        echo "Визначена сумісна версія: $LATEST_COMMON_VER"

        # Присвоюємо знайдену версію обом змінним
        VER_PEX_MGR="$LATEST_COMMON_VER"
        VER_PEX_CONF="$LATEST_COMMON_VER"
    fi
fi
#ПІДСУМКОВИЙ ЗВІТ
# --- RocketChat ---
if [[ "$SELECTED_APPS_STR" == *"RocketChat"* ]]; then
    echo -e "\n [ROCKET.CHAT FULL STACK]"
    if [[ "$VER_UBUNTU" != "ERROR" && "$VER_ROCKET" != "ERROR" ]]; then
        echo "   -> OS Base:  Ubuntu $VER_UBUNTU"
        echo "      Link:     ${MAP_UBUNTU[$VER_UBUNTU]}"
        echo "   -> App:      Rocket.Chat $VER_ROCKET"
        echo "      Channel:  ${MAP_ROCKET[$VER_ROCKET]}" # У вашому парсері лінк - це назва каналу, або змініть логіку
    else
        echo "   -> [SKIPPED] Помилка отримання списків."
    fi
fi

# --- Zabbix ---
if [[ "$SELECTED_APPS_STR" == *"Zabbix"* ]]; then
    echo -e "\n [ZABBIX APPLIANCE]"
    if [[ "$VER_ZABBIX" != "ERROR" ]]; then
        echo "   -> Version:  $VER_ZABBIX"
        echo "      Link:     ${MAP_ZABBIX[$VER_ZABBIX]}"
    else
        echo "   -> [SKIPPED] Немає даних."
    fi
fi

# --- Debian ---
if [[ "$SELECTED_APPS_STR" == *"Debian"* ]]; then
    echo -e "\n [DEBIAN CLOUD IMAGE]"
    if [[ "$VER_DEBIAN" != "ERROR" ]]; then
        echo "   -> Version:  Debian $VER_DEBIAN"
        echo "      Link:     ${MAP_DEBIAN[$VER_DEBIAN]}"
    else
        echo "   -> [SKIPPED] Немає даних."
    fi
fi

# --- Pexip Manager ---
if [[ "$SELECTED_APPS_STR" == *"Pexip_Mgr"* ]]; then
    echo -e "\n [PEXIP MANAGEMENT NODE]"
    if [[ "$VER_PEX_MGR" != "ERROR" ]]; then
        echo "   -> Version:  $VER_PEX_MGR"
        echo "      Link:     ${MAP_PEX_MGR[$VER_PEX_MGR]}"
    else
        echo "   -> [SKIPPED] Немає даних."
    fi
fi

# --- Pexip Conf ---
if [[ "$SELECTED_APPS_STR" == *"Pexip_Conf"* ]]; then
    echo -e "\n [PEXIP CONFERENCING NODE]"
    if [[ "$VER_PEX_CONF" != "ERROR" ]]; then
        echo "   -> Version:  $VER_PEX_CONF"
        echo "      Link:     ${MAP_PEX_CONF[$VER_PEX_CONF]}"
    else
        echo "   -> [SKIPPED] Немає даних."
    fi
fi

# Створюємо тимчасовий файл зі списком посилань
cat <<EOF > ./downloads.txt
${MAP_UBUNTU[$VER_UBUNTU]}
${MAP_ZABBIX[$VER_ZABBIX]}
${MAP_PEX_MGR[$VER_PEX_MGR]}
${MAP_PEX_CONF[$VER_PEX_CONF]}
EOF

# Запускаємо aria2c для роботи з цим файлом
# -j 4  означає завантажувати 4 файли одночасно
# -x 16 кількість з'єднань на один файл
# Якщо вона повертає помилку (не 0), виконується блок після ||
aria2c -d "$CLOUD_IMAGES_DIR" -i ./downloads.txt -j 4 -x 16 -c || {
    echo "Критична помилка завантаження! Активую скрипт видалення ПЗ..."
    rm ./downloads.txt
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    exit 1  # Завершуємо роботу поточного скрипта з кодом помилки
}

# Якщо завантаження пройшло успішно:
echo "Всі файли успішно завантажені!"
rm ./downloads.txt

#Дозволяємо запуск інсталятора
chmod +x ./bin/deploy.sh
#Птитаємо чи запускати встановлення
if whiptail --title "Встановлення" \
   --yes-button "Так" --no-button "Ні" \
   --yesno "Розпочати встановлення ?" 10 56; then

    echo "Користувач обрав 'Так'. Починаємо встановлення..."
    #Запуск встановлення
    ./bin/deploy.sh

else

    echo "Користувач обрав 'Ні'. Скасування."
fi
#Видалення програми для встановлення
sudo apt remove aria2
