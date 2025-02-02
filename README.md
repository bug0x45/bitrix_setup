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

После установки пакетов и их настройки, скрипт скачивает с официального сайта 1С-Битрикс файл "<b>bitrixsetup.php</b>" и размещает его по такому пути:

"<b>/var/www/html/bx-site</b>".

Запуск скрипта на выполнение:

1) Скачать файл "<b>run.sh</b>" и загрузить его на сервер под управлением Debian 12;
2) далее нужно дать файлу права на исполнение, сделать это можно командой "<b>chmod +x run.sh</b>", которую нужно прописать в терминале;
3) после запускаем командой "<b>./run.sh</b>" и ждем завершения работы скрипта.

Если в терминале нет ошибок, то открываем браузер и проверяем введя в адресной строке:

"<b>http://*IP-адрес Вашего сервера*/bitrixsetup.php</b>",

если открылся установщик Битрикс, значит всё прошло хорошо.

___________________

Доступы:

БД, пользователь и пароль создаются автоматически при работе данного скрипта.

MySQL:

  1) user: <b>bitrix</b>
  2) password: находится здесь: "<b>/var/www/html/bx-site/bitrix/php_interface/dbconn.php</b>"
  3) DB: <b>bitrix</b>
