# Установка `prplmesh-stock` на OpenWrt

**[English version](install-en.md)** · **[Релиз v1.0.0](https://github.com/krotname/openwrt-prplmesh-easymesh/releases/tag/v1.0.0)** · **[Воспроизводимая сборка](revision-1.md)**

Эта инструкция устанавливает пакет без замены существующих в OpenWrt
`wpad`, `hostapd` и `wpa_supplicant`. После установки пакет выключен. Сначала
настройте и проверьте его, только затем запускайте.

## 1. Проверка совместимости

Готовый бинарник v1.0.0 собран и проверен только на таком контроллере:

| Параметр | Поддерживаемый релизный бинарник |
|---|---|
| Роутер | Xiaomi/Redmi Router AX6S |
| Target OpenWrt | `mediatek/mt7622` |
| Архитектура пакета | `aarch64_cortex-a53` |
| Проверенная прошивка | OpenWrt `25.12.5`, Linux `6.12.94` |
| Обязательные управляющие сокеты AP | `/var/run/hostapd/wl0-ap0` и `/var/run/hostapd/wl1-ap0` |
| Мост LAN по умолчанию | `br-lan` |

OpenWrt 25.12 и новее используют APK. OpenWrt 24.10 и старше используют OPKG,
поэтому опубликованный `.apk` туда установить нельзя. Наличие APK в
development snapshot или совпадение названия архитектуры на другом роутере не
доказывают совместимость. Для другой платформы соберите пакет подходящим SDK и
отдельно проверьте результат. См. официальные материалы OpenWrt об
[APK](https://openwrt.org/docs/guide-user/additional-software/apk) и
[релизе 25.12](https://openwrt.org/releases/25.12/notes-25.12.0).

Первый запуск выполняйте по проводу и только при наличии физического доступа к
роутеру. Сначала выполните команды, которые ничего не изменяют:

```sh
ubus call system board
. /etc/os-release
printf 'release=%s target=%s\n' "$VERSION_ID" "$OPENWRT_BOARD"
apk --print-arch
uci show wireless
ls -l /var/run/hostapd/
uci -q get network.lan.device
```

Остановитесь, если отличаются модель, target, версия или архитектура. Текущий
init-скрипт также проверяет два имени сокетов из таблицы. Если мост LAN, секции
Wi-Fi или сокеты называются иначе, используйте сценарий сборки и проверки
целевого пакета — не подбирайте значения на удалённом роутере методом проб.

## 2. Создание и проверка внешней резервной копии

Следуйте официальной инструкции OpenWrt по
[резервному копированию и восстановлению](https://openwrt.org/docs/guide-user/troubleshooting/backup_restore).
На роутере:

```sh
umask 077
BACKUP="/tmp/backup-${HOSTNAME}-before-prplmesh-$(date +%Y%m%d-%H%M%S).tar.gz"
sysupgrade -b "$BACKUP"
tar -tzf "$BACKUP" >/dev/null
sha256sum "$BACKUP"
printf 'backup=%s\n' "$BACKUP"
```

До продолжения скопируйте показанный путь на другую машину:

```sh
scp root@АДРЕС_РОУТЕРА:/tmp/backup-ROUTER-before-prplmesh-TIMESTAMP.tar.gz .
tar -tzf backup-ROUTER-before-prplmesh-TIMESTAMP.tar.gz >/dev/null
sha256sum backup-ROUTER-before-prplmesh-TIMESTAMP.tar.gz
```

Если современный OpenSSH-клиент не соединяется с SCP-сервером роутера,
повторите копирование с `scp -O`, как указано в документации OpenWrt. Сравните
SHA-256 внешней копии со значением на роутере. Не продолжайте, если архив не
читается или хэши различаются. Единственная копия в `/tmp` не является
резервной.

## 3. Загрузка и проверка пакета

Команды ниже закреплены за документированным v1.0.0, а не за неизвестным
будущим `latest`:

```sh
cd /tmp
wget -O prplmesh-stock-6.0.1-r1.apk \
  https://github.com/krotname/openwrt-prplmesh-easymesh/releases/download/v1.0.0/prplmesh-stock-6.0.1-r1.apk
wget -O SHA256SUMS \
  https://github.com/krotname/openwrt-prplmesh-easymesh/releases/download/v1.0.0/SHA256SUMS
sha256sum -c SHA256SUMS
```

Ожидаемый SHA-256 APK для v1.0.0:

```text
6d398614bac7c1c3a5ad42edaf0f9638ce9999e1ea9877e232e81b2bc0f99ddf
```

Не используйте `--allow-untrusted`, пока проверка не выдала `OK`.

## 4. Установка без запуска

Обновите только индексы настроенных репозиториев и установите проверенный
локальный файл. Недостающие зависимости APK получит из настроенных официальных
репозиториев OpenWrt:

```sh
cat /etc/apk/repositories.d/distfeeds.list
apk update
apk add --allow-untrusted ./prplmesh-stock-6.0.1-r1.apk
apk list -I 'prplmesh-stock'
uci -q get prplmesh.config.enabled
```

Последняя команда должна вывести `0`. Если все зависимости уже установлены и
нужна полностью автономная установка, проверенный вариант выглядит так:

```sh
apk --network=no --allow-untrusted add ./prplmesh-stock-6.0.1-r1.apk
```

Не запускайте `apk upgrade`: OpenWrt отдельно предупреждает об опасности
слепого обновления всех пакетов.

## 5. Привязка конфигурации к роутеру

Ещё раз прочитайте реальные секции радио и сокеты hostapd, затем откройте
`/etc/config/prplmesh`:

```sh
uci show wireless
ubus list 'hostapd.*'
ls -l /var/run/hostapd/
vi /etc/config/prplmesh
```

Перед включением проверьте каждый пункт:

- все три значения `REPLACE_WITH_SSID` заменены одним нужным SSID;
- `key_passphrase` и оба поля `key` в профилях BSS заменены нужным паролем;
- `backhaul_wire_iface` указывает на фактический мост LAN (`br-lan` в
  проверенной сборке);
- `mandatory_interfaces` содержит два реальных AP-интерфейса;
- в каждой секции `wifi-device` правильно сопоставлены `hostap_iface`,
  `hostap_iface_steer_vaps`, `wireless_section` и `wireless_device`;
- профиль 2,4/5 ГГц использует выбранную политику защиты, а профиль 6 ГГц —
  SAE;
- во время проверки `enabled` остаётся равным `0`.

Публичный шаблон специально не содержит настоящий SSID и пароль. Не
публикуйте настроенный файл.

Локальная проверка перед запуском:

```sh
if grep -n 'REPLACE_WITH' /etc/config/prplmesh; then
    echo 'STOP: остались незаполненные значения'
    exit 1
fi
test -S /var/run/hostapd/wl0-ap0
test -S /var/run/hostapd/wl1-ap0
uci -q show prplmesh
uci changes prplmesh
uci commit prplmesh
```

Если хотя бы один сокет не найден, оставьте сервис выключенным. Упакованный
init-скрипт также откажется его запускать.

## 6. Контролируемый первый запуск

Запускайте только из проводной сессии:

```sh
uci set prplmesh.config.enabled='1'
uci commit prplmesh
/etc/init.d/prplmesh enable
/etc/init.d/prplmesh start
sleep 5
/etc/init.d/prplmesh status
ps w | grep -E '[i]eee1905_transport|[b]eerocks_(controller|agent)'
logread -e prplmesh | tail -n 100
```

Принимайте установку только при выполнении всех условий:

- проводная сессия управления и обычный шлюз LAN остаются доступны;
- `ieee1905_transport`, `beerocks_controller` и `beerocks_agent` работают без
  цикла перезапусков;
- существующие точки под управлением `wpad`/hostapd продолжают работать;
- каждый ожидаемый EasyMesh-агент виден как отдельный активный узел;
- для каждого проводного агента указан Ethernet, а не режим беспроводного
  повторителя;
- на каждом нужном диапазоне совпадают точные SSID и профиль защиты;
- посторонние проводные клиенты и сервисы в общей LAN остаются доступны.

Эти проверки не доказывают, что работают 802.11r/FT, MLO или роуминг без
потерь. Такие функции проверяются отдельно на всех участвующих точках и
клиентах.

## 7. Остановка, удаление и откат

Чтобы остановить сервис, сохранив пакет и конфигурацию:

```sh
uci set prplmesh.config.enabled='0'
uci commit prplmesh
/etc/init.d/prplmesh stop
/etc/init.d/prplmesh disable
```

Чтобы удалить пакет:

```sh
apk del prplmesh-stock
```

Проверьте, сохранился ли `/etc/config/prplmesh` как изменённый конфигурационный
файл. Удаляйте его вручную, только если он точно больше не нужен. Если после
остановки prplMesh радио не вернулись в прежнее состояние, из проводной сессии
перезагрузите конфигурацию Wi-Fi:

```sh
wifi reload
```

Полное восстановление через `sysupgrade -r` заменяет системную конфигурацию и
требует перезагрузки. Применяйте его только как аварийную процедуру с заранее
проверенным внешним архивом и по официальной инструкции OpenWrt.
