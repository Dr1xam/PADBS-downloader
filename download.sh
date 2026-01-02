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
#назва директорії програми
PROGRAM_DIR_NAME=$(mktemp)
# Створення тимчасових файлів
TMP_UBUNTU=$(mktemp)
TMP_ROCKET=$(mktemp)
TMP_ZABBIX=$(mktemp)
TMP_DEBIAN=$(mktemp)
TMP_PEX_MGR=$(mktemp)
TMP_PEX_CONF=$(mktemp)
TMP_SNAPD=$(mktemp)
TMP_CORES=$(mktemp)
#Колір графічного меню
export NEWT_COLORS='
# --- ВІКНО ТА ФОН ---
root=black,cyan          # Загальний фон екрану (все, що за межами вікна)
window=black,white       # Фон самого вікна діалогу
border=black,blue         # Рамка навколо вікна
shadow=black,black        # Тінь вікна (можна сховати, зробивши її black,black)
title=black,blue         # Заголовок вікна (наприклад "Встановлення")

# --- КНОПКИ (<Ok>, <Cancel>) ---
button=black,red        # Неактивна кнопка
actbutton=black,green     # Активна кнопка (на якій зараз курсор)
compactbutton=black,white # Компактні кнопки (рідко використовуються)

# --- СПИСКИ ТА МЕНЮ (Checklist, Radiolist) ---
listbox=black,black       # Невибраний елемент списку
actlistbox=black,green    # Вибраний елемент (на якому курсор)
actsellistbox=black,green # Активний і позначений елемент

# --- ЧЕКБОКСИ ([ ]) ---
checkbox=black,white      # Колір дужок [ ] і тексту неактивного чекбокса
actcheckbox=black,red # Колір дужок і тексту активного чекбокса

# --- ПОЛЯ ВВОДУ ТА ТЕКСТ ---
entry=black,green         # Поле, куди вводиться текст (Input box)
disentry=gray,black       # Заблоковане поле вводу
label=green,black         # Звичайний текст (напис)
textbox=black,white       # Текст у scroll-box (наприклад, ліцензія)
acttextbox=black,green    # Текст у scroll-box, коли він активний

# --- ІНШЕ ---
helpline=black,black     # Рядок підказки внизу (якщо є)
roottext=green,yellow     # Текст на фоні (рідко використовується)
emptyscale=black,blue    # Порожня частина прогрес-бару (Gauge)
fullscale=black,red     # Заповнена частина прогрес-бару (Gauge)
'
{
# Перевірка whiptail
if ! command -v whiptail &> /dev/null; then
    echo "Встановлення whiptail для графічного інтерфейсу"
    apt-get update -qq && apt-get install -y -qq whiptail
fi
sleep 0.5
echo -e "XXX\n10\nВстановлення aria2\nXXX"
sleep 0.5
if ! command -v aria2c &> /dev/null; then
    echo "Встановлення aria2 для багатопотокового завантаження"
    apt-get update -qq && apt-get install -y -qq aria2
fi

echo -e "XXX\n20\nЗавантаження коду програми\nXXX"
sleep 0.5
#Завантаження архіву з коом програми
aria2c -d "$DOWNLOAD_DIR" -x 16 -o "$PROGRAM_ARCHIVE_NAME" https://github.com/Dr1xam/PADBS-installer/archive/refs/tags/v0.1.3.tar.gz | sed 's/^/./'
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
basename "$PWD" > "$PROGRAM_DIR_NAME"
#створення директорій в програмі
mkdir "$TEMP_DIR"
mkdir "./resources"
mkdir "$CLOUD_IMAGES_DIR"
mkdir "$ISO_DIR"
mkdir "$SOFTWARE_DIR"
mkdir "$TAR_GZ_DIR"
echo -e "XXX\n30\nЗавантаження ansible\nXXX"
sleep 1
#Створюєм директрію з інсталяційними файлами піпу
mkdir "$SOFTWARE_DIR/pip"
#Переходимо у віртуальне середовище
source ./src/python/version-definder/venv/bin/activate
#Завантажуємо скрипт для встановлення піпу офлайн
python3 -c "import urllib.request; urllib.request.urlretrieve('https://bootstrap.pypa.io/get-pip.py', '$SOFTWARE_DIR/pip/get-pip.py')"
#Завантажуємо інсталяційні файли і залежності піпу
python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/pip/json'; data=json.load(urllib.request.urlopen(url)); f=next(x for x in data['urls'] if x['filename'].endswith('.whl')); print(f'Downloading {f['filename']}...'); full_path=os.path.join(path, f['filename']); urllib.request.urlretrieve(f['url'], full_path); print(f'Saved to: {os.path.abspath(full_path)}')"
python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/setuptools/json'; data=json.load(urllib.request.urlopen(url)); f=[x for x in data['urls'] if x['filename'].endswith('.whl')][0]; print('Downloading ' + f['filename']); urllib.request.urlretrieve(f['url'], os.path.join(path, f['filename'])); print('Saved to ' + path)"
python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/wheel/json'; data=json.load(urllib.request.urlopen(url)); f=[x for x in data['urls'] if x['filename'].endswith('.whl')][0]; print('Downloading ' + f['filename']); urllib.request.urlretrieve(f['url'], os.path.join(path, f['filename'])); print('Saved to ' + path)"
#Створюєм директрію з інсталяційними файлами ансібла
mkdir -p "$SOFTWARE_DIR/ansible"
#Завантажуємо інсталяційні файли енсібла
pip download ansible --dest $SOFTWARE_DIR/ansible/
echo -e "XXX\n56\nПошук версій\nXXX"
# Завантаження в багато потоків


# Запускаємо Python-парсери у фоні
{
    # Масив для зберігання PID
    pids=()

    # Запускаємо процеси у фоні
    python3 "$VERSION_DEFINDER_DIR/get-urls.py" ubuntu > "$TMP_UBUNTU" &
    pids+=($!)

    python3 "$VERSION_DEFINDER_DIR/get-urls.py" rocketchat > "$TMP_ROCKET" &
    pids+=($!)

    python3 "$VERSION_DEFINDER_DIR/get-urls.py" zabbix > "$TMP_ZABBIX" &
    pids+=($!)

    python3 "$VERSION_DEFINDER_DIR/get-urls.py" pexip_manage > "$TMP_PEX_MGR" &
    pids+=($!)

    python3 "$VERSION_DEFINDER_DIR/get-urls.py" pexip_conf > "$TMP_PEX_CONF" &
    pids+=($!)

    python3 "$VERSION_DEFINDER_DIR/get-urls.py" snapd > "$TMP_SNAPD" &
    pids+=($!)

    python3 "$VERSION_DEFINDER_DIR/get-urls.py" cores > "$TMP_CORES" &
    pids+=($!)

    # Загальна кількість завдань (має бути 7)
    total_tasks=${#pids[@]}

deactivate

    while true; do
        running_tasks=0

        # Перевіряємо кожен PID
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                ((running_tasks++))
            fi
        done

        # Розраховуємо кількість завершених
        completed_tasks=$((total_tasks - running_tasks))

        # Формула: Старт (44) + (Завершені * 8)
        percent=$((56 + 6 * completed_tasks))

        # Виводимо відсоток
        echo $percent

        # Якщо всі завершені - виходимо
        if [ "$running_tasks" -eq 0 ]; then
            # На всяк випадок дублюємо 100 та чекаємо трохи, щоб GUI встиг оновитись
            echo "100"
            sleep 1
            break
        fi

        sleep 0.5
    done
}


} | whiptail --title "Завантаження інсталятора та його залежностей" --gauge "Встановлення whiptail" 7 56 0
cd "$DOWNLOAD_DIR"
cd "$(cat "$PROGRAM_DIR_NAME")"
rm "$PROGRAM_DIR_NAME"

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

get_url_size() {
    line="$1"

    # Очищення від пробілів
    line=$(echo "$line" | xargs)

    if [[ "$line" != http* ]]; then
        return
    fi

    # Виводимо повідомлення в stderr (>&2), щоб не заважати підрахунку суми в stdout
    echo -n "Перевірка: ${line:0:30}... " > /dev/null

    # СПРОБА 1: Content-Length
    FILE_SIZE=$(curl -s -L -I "$line" --connect-timeout 5 --max-time 10 | grep -i "^Content-Length:" | tail -n 1 | awk '{print $2}' | tr -d '\r')

    # СПРОБА 2: Range Request (якщо перша не вдалася)
    if [[ -z "$FILE_SIZE" || ! "$FILE_SIZE" =~ ^[0-9]+$ ]]; then
        FILE_SIZE=$(curl -s -L -i -r 0-1 "$line" --connect-timeout 5 --max-time 10 | grep -i "Content-Range" | tail -n 1 | awk -F'/' '{print $2}' | tr -d '\r')
    fi

    # Результат
    if [[ -n "$FILE_SIZE" && "$FILE_SIZE" =~ ^[0-9]+$ ]]; then
        SIZE_MB=$((FILE_SIZE / 1024 / 1024))
        echo "OK ($SIZE_MB MB)" > /dev/null
        # ВАЖЛИВО: Виводимо лише байти в stdout для підсумовування
        echo "$FILE_SIZE"
    else
        echo "FAIL" > /dev/null
        echo "0"
    fi
}

{
# Створюємо тимчасовий файл зі списком посилань
touch ./temp/downloads.txt

if [[ "$SELECTED_APPS_STR" == *"RocketChat"* ]]; then
  echo "${MAP_UBUNTU[$VER_UBUNTU]}" >> ./temp/downloads.txt
  echo "${MAP_ROCKET[$VER_ROCKET]}" >> ./temp/downloads.txt
  echo "  out=rocketchat-server.snap" >> ./temp/downloads.txt
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

echo "Розрахунок загального розміру файлів (Deep Scan)..."
# Експортуємо функцію, щоб xargs міг її бачити
export -f get_url_size

echo "Починаємо сканування у 10 потоків..."
echo "-----------------------------------"

# 2. Запускаємо через xargs -P
# -P 10  : кількість потоків (змініть на потрібну)
# -n 1   : передавати по 1 рядку на виконання
# -I {}  : підстановка аргументу
# awk    : підсумовує вивід (stdout) від усіх потоків

TOTAL_BYTES=$(cat ./temp/downloads.txt | xargs -P 10 -I {} bash -c 'get_url_size "$@"' _ "{}" | awk '{s+=$1} END {print s}')

# Якщо TOTAL_BYTES порожній (помилка awk або файлу), ставимо 0
TOTAL_BYTES=${TOTAL_BYTES:-0}

# 3. Фінальний розрахунок
TOTAL_MB=$((TOTAL_BYTES / 1024 / 1024))


# Налаштування RPC
RPC_IP="127.0.0.1"
ALLOWED_PORTS=(6800 6801 6802 6803 6804 6805)
RPC_SECRET=$(openssl rand -hex 10)
LOG_FILE=$(mktemp)
RPC_PORT=""
ARIA_PID=""

# --- CLEANUP ---
cleanup() {
    if [[ -n "$ARIA_PID" ]] && kill -0 "$ARIA_PID" 2>/dev/null; then
        kill "$ARIA_PID" >/dev/null 2>&1
    fi
    rm -f "$LOG_FILE"
}
trap cleanup EXIT SIGINT SIGTERM

# --- ПІДКЛЮЧЕННЯ ---
echo "  Підготовка портів..."
for port in "${ALLOWED_PORTS[@]}"; do
    (echo > /dev/tcp/$RPC_IP/$port) >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        RPC_PORT=$port
        break
    fi
done

if [ -z "$RPC_PORT" ]; then
    echo " Всі порти зайняті!"
    exit 1
fi

# --- ЗАПУСК ARIA2C ---
stdbuf -o0 -e0 aria2c -d "$TEMP_DIR" -i ./temp/downloads.txt \
    -j 4 -x 16 -c \
    --enable-rpc --rpc-listen-port=$RPC_PORT --rpc-secret="$RPC_SECRET" \
    --rpc-listen-all=false \
    --summary-interval=0 \
    --console-log-level=warn \
    > "$LOG_FILE" 2>&1 &

ARIA_PID=$!

# --- ЧЕКАЄМО СТАРТ ---
SERVER_READY=0
for i in {1..40}; do
    if ! kill -0 "$ARIA_PID" 2> /dev/null; then
        echo "Aria2c впала."
        cat "$LOG_FILE"
        exit 1
    fi
    CHECK=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"ping\",\"method\":\"aria2.getVersion\",\"params\":[\"token:$RPC_SECRET\"]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")
    if [[ "$CHECK" == *"version"* ]]; then
        SERVER_READY=1
        break
    fi
    sleep 0.25
done

if [ $SERVER_READY -eq 0 ]; then
    echo "Тайм-аут сервера."
    exit 1
fi

echo "Завантаження..."

# --- ОСНОВНИЙ ЦИКЛ ---
while kill -0 "$ARIA_PID" 2> /dev/null; do

    # 1. СТАТУС ЧЕРГИ (для виходу)
    STAT_RES=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"stat\",\"method\":\"aria2.getGlobalStat\",\"params\":[\"token:$RPC_SECRET\"]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")

    NUM_ACTIVE=$(echo "$STAT_RES" | grep -o '"numActive":"[0-9]*"' | cut -d'"' -f4)
    NUM_WAITING=$(echo "$STAT_RES" | grep -o '"numWaiting":"[0-9]*"' | cut -d'"' -f4)

    # 2. ОТРИМАННЯ БАЙТІВ (Active + Waiting + Stopped)
    # МИ ДОДАЛИ ПАРАМЕТР ["completedLength"], ЩОБ ОТРИМАТИ ТІЛЬКИ ЦИФРИ І УНИКНУТИ ДУБЛІВ

    # Active (Те що качається)
    RES_ACTIVE=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"active\",\"method\":\"aria2.tellActive\",\"params\":[\"token:$RPC_SECRET\", [\"completedLength\"]]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")

    # Waiting (Черга - ми додали це, раніше цього не було!)
    RES_WAITING=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"waiting\",\"method\":\"aria2.tellWaiting\",\"params\":[\"token:$RPC_SECRET\", 0, 1000, [\"completedLength\"]]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")

    # Stopped (Готові)
    RES_STOPPED=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"stopped\",\"method\":\"aria2.tellStopped\",\"params\":[\"token:$RPC_SECRET\", 0, 1000, [\"completedLength\"]]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")

    # 3. СУМУВАННЯ
    # grep тепер знайде тільки правильні входження, бо ми відфільтрували зайве на етапі запиту
    CURRENT_BYTES=$(echo "$RES_ACTIVE $RES_WAITING $RES_STOPPED" | \
        grep -o '"completedLength":"[0-9]*"' | \
        cut -d'"' -f4 | \
        awk '{s+=$1} END {print s+0}')

    # 4. ВІЗУАЛІЗАЦІЯ
    CURRENT_MB=$((CURRENT_BYTES / 1024 / 1024))

    # Косметика: не показувати більше ніж Total
    DISPLAY_MB=$CURRENT_MB
    if [ "$DISPLAY_MB" -gt "$TOTAL_MB" ]; then DISPLAY_MB=$TOTAL_MB; fi

    PERCENT=$(( DISPLAY_MB * 100 / TOTAL_MB ))

    echo -e "$PERCENT"
    echo -e "XXX\n$PERCENT\n                 ($DISPLAY_MB MB / $TOTAL_MB MB)\nXXX"

    # 5. УМОВА ВИХОДУ
    # Виходимо тільки коли все завершено (нема активних, нема в черзі)
    if [[ "$NUM_ACTIVE" == "0" && "$NUM_WAITING" == "0" ]]; then
        if [ "$CURRENT_BYTES" -gt 0 ] || [ "$TOTAL_BYTES" -eq 0 ]; then
             echo 100
             break
        fi
    fi

    sleep 1
done


echo -e "XXX\n100\n                    Фіналізація\nXXX"

# Ввічливе вимкнення
curl -s -X POST -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":\"bye\",\"method\":\"aria2.shutdown\",\"params\":[\"token:$RPC_SECRET\"]}" \
    "http://$RPC_IP:$RPC_PORT/jsonrpc" > /dev/null

wait "$ARIA_PID"
echo "Всі файли успішно завантажені!"

#Попереносити ї по своїх місцях!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
} | whiptail --title "Завантаження образів" --gauge "Підготовка" 7 56 0
{
if [[ "$SELECTED_APPS_STR" == *"RocketChat"* ]]; then

        echo "" > ./temp/downloads.txt
        echo "${MAP_SNAPD[$VER_SNAPD]}" >> ./temp/downloads.txt
        echo "  out=snapd.snap" >> ./temp/downloads.txt

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

      echo "${CORE_URL}" >> ./temp/downloads.txt
      echo "  out=${SNAPD_BASE}.snap" >> ./temp/downloads.txt

      echo "Розрахунок загального розміру файлів (Deep Scan)..."
# Експортуємо функцію, щоб xargs міг її бачити
export -f get_url_size

echo "Починаємо сканування у 10 потоків..."
echo "-----------------------------------"

# 2. Запускаємо через xargs -P
# -P 10  : кількість потоків (змініть на потрібну)
# -n 1   : передавати по 1 рядку на виконання
# -I {}  : підстановка аргументу
# awk    : підсумовує вивід (stdout) від усіх потоків

TOTAL_BYTES=$(cat ./temp/downloads.txt | xargs -P 10 -I {} bash -c 'get_url_size "$@"' _ "{}" | awk '{s+=$1} END {print s}')

# Якщо TOTAL_BYTES порожній (помилка awk або файлу), ставимо 0
TOTAL_BYTES=${TOTAL_BYTES:-0}

# 3. Фінальний розрахунок
TOTAL_MB=$((TOTAL_BYTES / 1024 / 1024))

      # Налаштування RPC
RPC_IP="127.0.0.1"
ALLOWED_PORTS=(6800 6801 6802 6803 6804 6805)
RPC_SECRET=$(openssl rand -hex 10)
LOG_FILE=$(mktemp)
RPC_PORT=""
ARIA_PID=""

# --- CLEANUP ---
cleanup() {
    if [[ -n "$ARIA_PID" ]] && kill -0 "$ARIA_PID" 2>/dev/null; then
        kill "$ARIA_PID" >/dev/null 2>&1
    fi
    rm -f "$LOG_FILE"
}
trap cleanup EXIT SIGINT SIGTERM

# --- ПІДКЛЮЧЕННЯ ---
echo "  Підготовка портів..."
for port in "${ALLOWED_PORTS[@]}"; do
    (echo > /dev/tcp/$RPC_IP/$port) >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        RPC_PORT=$port
        break
    fi
done

if [ -z "$RPC_PORT" ]; then
    echo " Всі порти зайняті!"
    exit 1
fi

# --- ЗАПУСК ARIA2C ---
stdbuf -o0 -e0 aria2c -d "$TEMP_DIR" -i ./temp/downloads.txt \
    -j 4 -x 16 -c \
    --enable-rpc --rpc-listen-port=$RPC_PORT --rpc-secret="$RPC_SECRET" \
    --rpc-listen-all=false \
    --summary-interval=0 \
    --console-log-level=warn \
    > "$LOG_FILE" 2>&1 &

ARIA_PID=$!

# --- ЧЕКАЄМО СТАРТ ---
SERVER_READY=0
for i in {1..40}; do
    if ! kill -0 "$ARIA_PID" 2> /dev/null; then
        echo "Aria2c впала."
        cat "$LOG_FILE"
        exit 1
    fi
    CHECK=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"ping\",\"method\":\"aria2.getVersion\",\"params\":[\"token:$RPC_SECRET\"]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")
    if [[ "$CHECK" == *"version"* ]]; then
        SERVER_READY=1
        break
    fi
    sleep 0.25
done

if [ $SERVER_READY -eq 0 ]; then
    echo "Тайм-аут сервера."
    exit 1
fi

echo "Завантаження..."

# --- ОСНОВНИЙ ЦИКЛ ---
while kill -0 "$ARIA_PID" 2> /dev/null; do

    # 1. СТАТУС ЧЕРГИ (для виходу)
    STAT_RES=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"stat\",\"method\":\"aria2.getGlobalStat\",\"params\":[\"token:$RPC_SECRET\"]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")

    NUM_ACTIVE=$(echo "$STAT_RES" | grep -o '"numActive":"[0-9]*"' | cut -d'"' -f4)
    NUM_WAITING=$(echo "$STAT_RES" | grep -o '"numWaiting":"[0-9]*"' | cut -d'"' -f4)

    # 2. ОТРИМАННЯ БАЙТІВ (Active + Waiting + Stopped)
    # МИ ДОДАЛИ ПАРАМЕТР ["completedLength"], ЩОБ ОТРИМАТИ ТІЛЬКИ ЦИФРИ І УНИКНУТИ ДУБЛІВ

    # Active (Те що качається)
    RES_ACTIVE=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"active\",\"method\":\"aria2.tellActive\",\"params\":[\"token:$RPC_SECRET\", [\"completedLength\"]]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")

    # Waiting (Черга - ми додали це, раніше цього не було!)
    RES_WAITING=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"waiting\",\"method\":\"aria2.tellWaiting\",\"params\":[\"token:$RPC_SECRET\", 0, 1000, [\"completedLength\"]]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")

    # Stopped (Готові)
    RES_STOPPED=$(curl -s -X POST -H 'Content-Type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"stopped\",\"method\":\"aria2.tellStopped\",\"params\":[\"token:$RPC_SECRET\", 0, 1000, [\"completedLength\"]]}" \
        "http://$RPC_IP:$RPC_PORT/jsonrpc")

    # 3. СУМУВАННЯ
    # grep тепер знайде тільки правильні входження, бо ми відфільтрували зайве на етапі запиту
    CURRENT_BYTES=$(echo "$RES_ACTIVE $RES_WAITING $RES_STOPPED" | \
        grep -o '"completedLength":"[0-9]*"' | \
        cut -d'"' -f4 | \
        awk '{s+=$1} END {print s+0}')

    # 4. ВІЗУАЛІЗАЦІЯ
    CURRENT_MB=$((CURRENT_BYTES / 1024 / 1024))

    # Косметика: не показувати більше ніж Total
    DISPLAY_MB=$CURRENT_MB
    if [ "$DISPLAY_MB" -gt "$TOTAL_MB" ]; then DISPLAY_MB=$TOTAL_MB; fi

    PERCENT=$(( DISPLAY_MB * 100 / TOTAL_MB ))

    echo -e "$PERCENT"
    echo -e "XXX\n$PERCENT\n                 ($DISPLAY_MB MB / $TOTAL_MB MB)\nXXX"

    # 5. УМОВА ВИХОДУ
    # Виходимо тільки коли все завершено (нема активних, нема в черзі)
    if [[ "$NUM_ACTIVE" == "0" && "$NUM_WAITING" == "0" ]]; then
        if [ "$CURRENT_BYTES" -gt 0 ] || [ "$TOTAL_BYTES" -eq 0 ]; then
             echo 100
             break
        fi
    fi

    sleep 1
done


echo -e "XXX\n100\n                    Фіналізація\nXXX"

# Ввічливе вимкнення
curl -s -X POST -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":\"bye\",\"method\":\"aria2.shutdown\",\"params\":[\"token:$RPC_SECRET\"]}" \
    "http://$RPC_IP:$RPC_PORT/jsonrpc" > /dev/null

wait "$ARIA_PID"
echo "Всі файли успішно завантажені!"
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
  if [[ -f "$TEMP_DIR/snapd.snap" ]]; then
    mv -f "$TEMP_DIR/snapd.snap" "$SOFTWARE_DIR/"
    echo " -> snapd.snap переміщено в $SOFTWARE_DIR"
  fi

  # Переміщення ядра (Core), якщо воно було завантажено
  # $SNAPD_BASE ми отримали раніше (наприклад, core22)
  if [[ -n "$SNAPD_BASE" && -f "$TEMP_DIR/${SNAPD_BASE}.snap" ]]; then
    mv -f "$TEMP_DIR/${SNAPD_BASE}.snap" "$SOFTWARE_DIR/"
    echo " -> ${SNAPD_BASE}.snap переміщено в $SOFTWARE_DIR"
  fi
fi

rm ./temp/downloads.txt
} | whiptail --title "Завантаження програм" --gauge "Підготовка" 7 56 0
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
