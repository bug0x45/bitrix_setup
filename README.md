# Установщик Битрикс на Debian 12

Bash скрипт для автоматической установки 1С-Битрикс на Debian 12.

Данный код производит установку нужных для работы Битрикс пакетов:

1) Apache2 v2.4
2) Nginx v1.22
3) MySQL v8.0
4) PHP v8.3
5) NodeJS v18.19
6) NPM v.9.2
7) Redis v.7.0

а так же производит необходимые настройки используя официальную документацию Битрикс.

После установки пакетов и их настройки, скрипт скачивает с официального сайта 1С-Битрикс файл "bitrixsetup.php" и размещает его по такому пути:

"/var/www/html/bx-site".

Запуск скрипта на выполнение:

1) Скачать файл "run.sh" и загрузить его на сервер под управлением Debian 12;
2) далее нужно дать файлу права на исполнение, сделать это можно командой "chmod +x run.sh", которую нужно прописать в терминале;
3) после запускаем командой "./run.sh" и ждем завершения работы скрипта.

Если в терминале нет ошибок и всё прошло хорошо, то открываем браузер и проверяем введя в адресной строке:

"http://*IP-адрес Вашего сервера*/bitrixsetup.php",

если открылся установщик Bitrix, значит всё прошло хорошо.

___________________

Доступы:

MySQL:

  БД, пользователь и пароль создаются автоматически при работе данного скрипта.

  user: bitrix
  password:
    находится здесь: /var/www/html/bx-site/bitrix/php_interface/dbconn.php
  DB: bitrix
