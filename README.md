# meslog
Parse mail log file with search by recipient address

Ниже перечислены скрипты в порядке их запуска.

## 1st_create_meslogDB.sh
Определяет минималььно допустимые размеры некоторых (необходимых) текстовых полей 
таблиц базы данных (БД) **message** , **log** и создаёт их.

Внутри скрипта надо настроить 2 переменные:

```bash
logFile=mailog.out # log-файл, который служит для наполнения таблиц БД
user=alessandro # пользователь БД
```
Предполагается, что MySQL уже установлен и настроена учетная запись пользователя 
(в примере по умолчанию *alessandro*)

В каталоге **example** находится пример *logFile* (*mailog.out*).

### ПРИМЕНЕНИЕ

```bash
./1st_create_meslogDB.sh
```

## 2nd-filling_meslogDB.pl
Заполняет таблицы **message** и **log** базы данных **meslogDB** (по умолчанию)
из файла *mailog.out* (по умолчанию).

### ПРИМЕНЕНИЕ

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

:star: *--errlog* - Сохранять ERROR log файл. По умолчанию, 'filling_meslogDB.errors'.

:star: *--cfg_db*  - файл конфигурации БД. По умолчанию, 'local_settings.json'.

:star: *--session* - название сессии в файле конфигурации БД. По умолчанию, 'meslogDB'.

:star: *--verbose* - Выводить подробную информацию во времф работы скрипта.

:star: *--help* - Вывод справки.

Примечание:

Необходим файл конфигурации БД 'local_settings.json' (или указанные через --cfg_db).

