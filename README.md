# meslog
Parse mail log file with search by recipient address

Ниже перечислены скрипты в порядке их запуска.

## 1st_create_meslogDB.sh
Определяет минимально допустимые размеры некоторых (необходимых) текстовых полей 
таблиц базы данных (БД) **message**, **log** и создаёт их.

Внутри скрипта надо настроить 2 переменные:

```bash
logFile=mailog.out # log-файл, который служит для наполнения таблиц БД
user=alessandro # пользователь БД
```
Предполагается, что MySQL уже установлен и настроена учетная запись пользователя 
(в примере по умолчанию *alessandro*)

В каталоге **example** находится пример *logFile* (*mailog.out*).

### Применение

```bash
./1st_create_meslogDB.sh
```

***

## 2nd-filling_meslogDB.pl
Заполняет таблицы **message** и **log** базы данных **meslogDB** (по умолчанию)
из файла *mailog.out* (по умолчанию).

Дамп заполненной БД (с двумя таблицами) находится в каталоге **db**.

### Применение

```bash
./2nd-filling_meslogDB.pl <file.log> [OPTIONS]
```

Example:
```bash
./2nd-filling_meslogDB.pl mailog.out -v
```

Здесь:

:star: *<file.log>* - входящий log-файл для наполнения таблиц БД.

OPTIONS:

:star: *--errlog* - сохранять ERROR log файл. По умолчанию, *filling_meslogDB.errors*. 
       В этот файл отправляются всё, что не подходит для хранения в таблицах БД.

:star: *--cfg_db*  - файл конфигурации БД. По умолчанию, *local_settings.json*.

:star: *--session* - название сессии в файле конфигурации БД. По умолчанию, *meslogDB*.

:star: *--verbose* - Выводить подробную информацию во время работы скрипта.

:star: *--help* - Вывод справки.

Примечание:

Необходим файл конфигурации БД *local_settings.json* (или указанные через --cfg_db).

***

## web/cgi-bin/webmeslog.pl
Анализирует адрес получателя (*email*), который приходит от пользователя через
web-форму поиска **web/html/index.html**.
В итоге формирует (если есть) две таблицы со списком 
найденных записей *timestamp* (время появления в логе), *flag лога*, *строка лога*.

Предполагается, что Web-сервер (Apache) уже установлен и настроен.
html-файл с поисковой формой **web/html/index.html** находится в корневом каталоге Web для статических htmml-страниц
(например, */var/www/html*), а скрипт **webmeslog.pl** находится в каталоге для исполняемых скриптов **cgi-bin**
(например, */usr/lib/cgi-bin*), иначе, указать другое расположение скрипта в файле *index.html*:

```bash
grep -n webmeslog.pl index.html

## 12:<form method="post" action="/cgi-bin/webmeslog.pl">
```

В скрипте **webmeslog.pl** можно настроить расположение файла конфигурации БД (по умолчанию, *local_settings.json*):

```perl
my $CFG_DB = 'local_settings.json';	# must be installed
```

