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
CLOUD_IMAGES_DIR="./resources/cloud-images"
#Розташування ісо
ISO_DIR="./resources/iso"
#Розташування розархівованих інсталяторів програм
SOFTWARE_DIR="./resources/software"
#Розташування програми пошуку посилань
VERSION_DEFINDER_DIR="./src/python/version-definder"
#Розташування каталогу із тимчасовими файлами
TEMP_DIR="./temp"

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
aria2c -d "$DOWNLOAD_DIR" -x 16 -o "$PROGRAM_ARCHIVE_NAME" https://github.com/Dr1xam/PADBS-installer/archive/refs/tags/v0.1.3.tar.gz
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
mkdir "$TEMP_DIR"
mkdir "./resources"
mkdir "$CLOUD_IMAGES_DIR"
mkdir "$ISO_DIR"
mkdir "$SOFTWARE_DIR"
mkdir "$TAR_GZ_DIR"
#Створюєм директрію з інсталяційними файлами піпу
mkdir "$SOFTWARE_DIR/pip"
#Переходимо у віртуальне середовище
source ./src/python/version-definder/venv/bin/activate
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
TMP_SNAPD=$(mktemp)
TMP_CORES=$(mktemp)

# Запускаємо Python-парсери у фоні
{
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" ubuntu > "$TMP_UBUNTU" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" rocketchat > "$TMP_ROCKET" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" zabbix > "$TMP_ZABBIX" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" debian > "$TMP_DEBIAN" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" pexip_manage > "$TMP_PEX_MGR" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" pexip_conf > "$TMP_PEX_CONF" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" snapd > "$TMP_SNAPD" &
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" cores > "$TMP_CORES" &
    wait
} | whiptail --gauge "Отримання списків версій для всіх програм..." 6 60 0

# Оголошення асоціативних масивів для лінків
declare -A MAP_UBUNTU
declare -A MAP_ROCKET
declare -A MAP_ZABBIX
declare -A MAP_DEBIAN
declare -A MAP_PEX_MGR
declare -A MAP_PEX_CONF
declare -A MAP_SNAPD
declare -A MAP_CORES
# Оголошення масивів для меню
MENU_UBUNTU=()
MENU_ROCKET=()
MENU_ZABBIX=()
MENU_DEBIAN=()
MENU_PEX_MGR=()
MENU_PEX_CONF=()
MENU_SNAPD=()
MENU_CORES=()
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
load_data "$TMP_SNAPD" MENU_SNAPD MAP_SNAPD
load_data "$TMP_CORES" MENU_CORES MAP_CORES
# Видаляємо тимчасові файли
rm "$TMP_UBUNTU" "$TMP_ROCKET" "$TMP_ZABBIX" "$TMP_DEBIAN" "$TMP_PEX_MGR" "$TMP_PEX_CONF" "$TMP_SNAPD" "$TMP_CORES"
#Вибір програм(Меню (головне))
while true; do
    RAW_APPS=$(whiptail --title "Менеджер завантажень" --checklist \
    "Які продукти ви хочете завантажити?" 20 56 5 \
    "RocketChat"  "Rocket.Chat Server (+ Ubuntu Base)" ON \
    "Zabbix"      "Zabbix Appliance (.ovf)" ON \
    "Pexip_Mgr"   "Pexip Management Node (.ova)" ON \
    "Pexip_Conf"  "Pexip Conferencing Node (.ova)" ON \
    3>&1 1>&2 2>&3)
#    "Debian"      "Debian Cloud Image (.qcow2)" ON \
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

# --- ROCKET CHAT ---
if [[ "$SELECTED_APPS_STR" == *"RocketChat"* ]]; then
    echo "Налаштування RocketChat..."

    # 1. Автоматичний вибір Ubuntu Base
    if [ ${#MENU_UBUNTU[@]} -gt 0 ]; then
        VER_UBUNTU="${MENU_UBUNTU[0]}"
        echo "   -> Автоматично обрано Ubuntu Base: $VER_UBUNTU"
    else
        VER_UBUNTU="ERROR"
        whiptail --msgbox "Не вдалося автоматично визначити версію Ubuntu!" 8 52
    fi

    # 2. Автоматичний вибір Snapd (ДОДАНО)
    if [ ${#MENU_SNAPD[@]} -gt 0 ]; then
        # Беремо перший елемент (найновіша версія)
        VER_SNAPD="${MENU_SNAPD[0]}"
        echo "   -> Автоматично обрано Snapd: $VER_SNAPD"
    else
        VER_SNAPD="ERROR"
        echo "   -> [ПОМИЛКА] Не вдалося знайти версію Snapd!"
    fi

    # 3. Ручний вибір RocketChat
    safe_select "RocketChat -> Application" "Оберіть версію RocketChat:" MENU_ROCKET VER_ROCKET
fi

# --- ZABBIX ---
if [[ "$SELECTED_APPS_STR" == *"Zabbix"* ]]; then
    safe_select "Zabbix Appliance" "Оберіть версію Zabbix:" MENU_ZABBIX VER_ZABBIX
fi

# --- DEBIAN ---
#if [[ "$SELECTED_APPS_STR" == *"Debian"* ]]; then
#    safe_select "Debian Cloud" "Оберіть версію Debian (Backports):" MENU_DEBIAN VER_DEBIAN
#fi

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
# Створюємо тимчасовий файл зі списком посилань
touch ./temp/downloads.txt

if [[ "$SELECTED_APPS_STR" == *"RocketChat"* ]]; then
  echo "${MAP_UBUNTU[$VER_UBUNTU]}" >> ./temp/downloads.txt
  echo "${MAP_ROCKET[$VER_ROCKET]}" >> ./temp/downloads.txt
  echo "  out=rocketchat-server.snap" >> ./temp/downloads.txt
  echo "${MAP_SNAPD[$VER_SNAPD]}" >> ./temp/downloads.txt
  echo "  out=snapd.snap" >> ./temp/downloads.txt
fi

if [[ "$SELECTED_APPS_STR" == *"Zabbix"* ]]; then
  echo "${MAP_ZABBIX[$VER_ZABBIX]}" >> ./temp/downloads.txt
fi

if [[ "$SELECTED_APPS_STR" == *"Pexip_Mgr"* ]]; then
  echo "${MAP_PEX_MGR[$VER_PEX_MGR]}" >> ./temp/downloads.txt
fi

if [[ "$SELECTED_APPS_STR" == *"Pexip_Conf"* ]]; then
  echo "${MAP_PEX_CONF[$VER_PEX_CONF]}" >> ./temp/downloads.txt
fi


# Запускаємо aria2c для роботи з цим файлом
# -j 4  означає завантажувати 4 файли одночасно
# -x 16 кількість з'єднань на один файл
# Якщо вона повертає помилку (не 0), виконується блок після ||
aria2c -d "$TEMP_DIR" -i ./temp/downloads.txt -j 4 -x 16 -c || {
    echo "Критична помилка завантаження! Активую скрипт видалення ПЗ..."

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    exit 1  # Завершуємо роботу поточного скрипта з кодом помилки
}

# Якщо завантаження пройшло успішно:
echo "Всі файли успішно завантажені!"

#Попереносити ї по своїх місцях!!!!!!!!!!!!!!!!!!!!!!!!!!!
if [[ -f "$TEMP_DIR/snapd.snap" ]]; then
    mv -f "$TEMP_DIR/snapd.snap" "$SOFTWARE_DIR/"
    echo " -> snapd.snap переміщено в $SOFTWARE_DIR"
fi

# Переміщення RocketChat
if [[ -f "$TEMP_DIR/rocketchat-server.snap" ]]; then
    mv -f "$TEMP_DIR/rocketchat-server.snap" "$SOFTWARE_DIR/"
    echo " -> rocketchat-server.snap переміщено в $SOFTWARE_DIR"
fi

# --- 2. Переміщення хмарних образів (Cloud Images) ---

# Ubuntu Base
# Шукаємо файл за маскою, бо ми могли назвати його ubuntu-20.04.ova або ubuntu-22.04.ova
# Але в aria2 ми прописали out=ubuntu-base.tar.gz (або .ova, перевірте як у вас в cat <<EOF)
# Ubuntu
# 2>/dev/null ховає помилку "No such file", якщо файлів немає
if mv "$TEMP_DIR"/ubuntu*.ova "$CLOUD_IMAGES_DIR/" 2>/dev/null; then
    echo " -> Ubuntu Base переміщено в $CLOUD_IMAGES_DIR"
fi

# Zabbix
if mv "$TEMP_DIR"/zabbix*.tar.gz "$CLOUD_IMAGES_DIR/" 2>/dev/null; then
    echo " -> Zabbix Appliance переміщено в $CLOUD_IMAGES_DIR"
fi

# Pexip Manager
if mv "$TEMP_DIR"/Pexip*pxMgr*.ova "$CLOUD_IMAGES_DIR/" 2>/dev/null; then
    echo " -> Pexip Manager переміщено в $CLOUD_IMAGES_DIR"
fi

# Pexip Conference
if mv "$TEMP_DIR"/Pexip*ConfNode*.ova "$CLOUD_IMAGES_DIR/" 2>/dev/null; then
    echo " -> Pexip ConfNode переміщено в $CLOUD_IMAGES_DIR"
fi


if [[ "$SELECTED_APPS_STR" == *"RocketChat"* ]]; then
  SNAPD_FILE="$SOFTWARE_DIR/rocketchat-server.snap"

  # 2. Читаємо meta/snap.yaml прямо з архіву
  # snapd часто не має параметра "base", бо він сам є базовим інструментом.
  # Тому результат може бути порожнім.
  SNAPD_BASE=$(unsquashfs -cat "$SNAPD_FILE" meta/snap.yaml | grep "base:" | awk '{print $2}')

  if [[ -n "$SNAPD_BASE" ]]; then
    echo "Виявлено залежність від ядра: $SNAPD_BASE"

    # Отримуємо URL з масиву MAP_CORES за ключем (наприклад, core22)
    CORE_URL="${MAP_CORES[$SNAPD_BASE]}"

    if [[ -n "$CORE_URL" ]]; then
        echo "Знайдено посилання для $SNAPD_BASE. Додавання в чергу завантаження..."

     # Створюємо файл списку завантаження спеціально для ядра
cat <<EOF > ./temp/downloads.txt
$CORE_URL
  out=${SNAPD_BASE}.snap
EOF

      # Завантажуємо ядро в ту ж тимчасову папку
      aria2c -d "$TEMP_DIR" -i ./temp/downloads.txt -j 4 -x 16 -c || {
        echo "Критична помилка завантаження ядра $SNAPD_BASE!"
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        exit 1
      }

        # Прибираємо тимчасовий файл списку
        echo "Ядро $SNAPD_BASE успішно завантажено в $TEMP_DIR"
    else
        # Якщо в MAP_CORES немає такого ключа (наприклад, core16, якого ми не парсили)
        echo "УВАГА: Посилання для '$SNAPD_BASE' відсутнє в отриманому списку версій!"
        echo "Перевірте, чи ваш парсер cores підтримує цю версію."
        #!!!!!!!!!!!!!!!!!!!!!!
    fi
  else
    echo "Інформація: Параметр 'base' у файлі $SNAPD_FILE відсутній або порожній."
    #!!!!!!!!!!!!!!!!!!!!!!!!!!
  fi

  #перенести все по місяцям !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # Переміщення ядра (Core), якщо воно було завантажено
  # $SNAPD_BASE ми отримали раніше (наприклад, core22)
  if [[ -n "$SNAPD_BASE" && -f "$TEMP_DIR/${SNAPD_BASE}.snap" ]]; then
    mv -f "$TEMP_DIR/${SNAPD_BASE}.snap" "$SOFTWARE_DIR/"
    echo " -> ${SNAPD_BASE}.snap переміщено в $SOFTWARE_DIR"
  fi
fi

rm ./temp/downloads.txt

deactivate
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
