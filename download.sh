#!/bin/bash

DOWNLOAD_DIR="/var/lib/vz/snippets"

VERSION_DEFINDER_DIR="./src/python/version_definder"

PROGRAM_ARCHIVE_NAME="PADBS.tar.gz"

TAR_GZ_DIR="./resources/software/tar-gz"
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

aria2c -d "$DOWNLOAD_DIR" -x 16 -o "$PROGRAM_ARCHIVE_NAME" https://github.com/Dr1xam/PADBS/archive/refs/tags/v1.0.0-legacy.tar.gz

cd "$DOWNLOAD_DIR"

# 1. Визначаємо назву кореневої папки, не розпаковуючи
# (беремо список файлів -> перший рядок -> відрізаємо все після першого слеша)
DIR_NAME=$(tar -tf "$PROGRAM_ARCHIVE_NAME" | head -1 | cut -d/ -f1)

# 2. Розпаковуємо
tar -xzvf "$PROGRAM_ARCHIVE_NAME"

# 3. Перевіряємо, чи це справді папка, і заходимо
    cd "$DIR_NAME"

mkdir "./resources"
mkdir "./resources/cloud-images"
mkdir "./resources/iso"
mkdir "$SOFTWARE_DIR"
mkdir "$TAR_GZ_DIR"

mkdir "$SOFTWARE_DIR/pip"
python3 -c "import urllib.request; urllib.request.urlretrieve('https://bootstrap.pypa.io/get-pip.py', '$SOFTWARE_DIR/pip/get-pip.py')"

python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/pip/json'; data=json.load(urllib.request.urlopen(url)); f=next(x for x in data['urls'] if x['filename'].endswith('.whl')); print(f'Downloading {f['filename']}...'); full_path=os.path.join(path, f['filename']); urllib.request.urlretrieve(f['url'], full_path); print(f'Saved to: {os.path.abspath(full_path)}')"
python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/setuptools/json'; data=json.load(urllib.request.urlopen(url)); f=[x for x in data['urls'] if x['filename'].endswith('.whl')][0]; print('Downloading ' + f['filename']); urllib.request.urlretrieve(f['url'], os.path.join(path, f['filename'])); print('Saved to ' + path)"
python3 -c "import json, urllib.request, os; path='$SOFTWARE_DIR/pip/'; os.makedirs(path, exist_ok=True); url='https://pypi.org/pypi/wheel/json'; data=json.load(urllib.request.urlopen(url)); f=[x for x in data['urls'] if x['filename'].endswith('.whl')][0]; print('Downloading ' + f['filename']); urllib.request.urlretrieve(f['url'], os.path.join(path, f['filename'])); print('Saved to ' + path)"

mkdir -p "$SOFTWARE_DIR/ansible"
pip download ansible --dest $SOFTWARE_DIR/ansible/

sudo apt remove aria2