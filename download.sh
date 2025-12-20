#!/bin/bash
#дерикторія в яку завантажиться інсталятор
DOWNLOAD_DIR="/var/lib/vz/snippets"
#Дерикторія прграми порсингу силок
VERSION_DEFINDER_DIR="./src/python/version_definder"
#Назва архіву з кодом програми
PROGRAM_ARCHIVE_NAME="PADBS.tar.gz"
#Розташування архівованих інсталяторів програм 
TAR_GZ_DIR="./resources/software/tar-gz"
#Розташування розархівованих інсталяторів програм
SOFTWARE_DIR="./resources/software"

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
#Дозволяємо запуск інсталятора
chmod +x ./bin/deploy.sh
#Птитаємо чи запускати встановлення
if whiptail --title "Встановлення" \
   --yes-button "Так" --no-button "Ні" \
   --yesno "Розпочати встановлення ?" 10 60; then

    echo "Користувач обрав 'Так'. Починаємо встановлення..."
    #Запуск встановлення
    ./bin/deploy.sh
    
else
 
    echo "Користувач обрав 'Ні'. Скасування."
fi
#Видалення програми для встановлення
sudo apt remove aria2
