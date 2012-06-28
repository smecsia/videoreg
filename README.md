1. Составляется конфиг-файл config.rb:

	reg {
	  device	  '/dev/video0'
	  resolution  '640x480'
	  fps		  25
	  duration	  30
	  filename	  '#{time}-video0.avi'
	  storage	  '/tmp/video0'
	  lockfile	  '/tmp/videoreg.video0.lock'
	  store_max   5
	}

	reg {
	  device      '/dev/video1'
	  resolution  '640x480'
	  fps         25
	  duration    30
	  filename    '#{time}-video1.avi'
	  storage     '/tmp/video1'
	  lockfile    '/tmp/videoreg.video1.lock'
	  store_max   3
	}

	run :all

1. После установки скриптов на машине запуск регистрации происходит при помощи команды videoreg:

	$ videoreg -h
    Usage: videoreg [options]
        -c, --config CONFIG              Use the specified config
        -d, --device DEVICE              Run only the specified device
        -e, --ensure                     Check the state of the daemon
        -H, --halt DEVICE                Halt (suspend) the specified device
        -r, --recover DEVICE             Recover the device
        -P, --pid PID                    Set the PID file for the capture process
        -l, --log LOGFILE                Set the logfile for daemon
        -R, --reset                      Reset the state (remove lock-files)
        -k, --kill                       Kills the capture processes
        -v, --version                    Show the version
        -h, --help                       Show this help message

1. Соответственно запуск демона осуществляется следующим образом:

	$ videoreg -s config.rb -l /tmp/videoreg.log
	Daemon has started successfully

1. Остановка:

	$ videoreg -s config.rb -l /tmp/videoreg.log --kill
	Stopped PID: 3870 at /tmp/videoreg.pid

# Changelog

## 28.06.2012
### Current status
* Запуск видеозаписи
    * Параметры для всех камер хранятся в одном конфиге (разрешение, фпс, длительность каждого файла)
    * Запись по кускам (по 10минут в один файл например)
    * Слежение

### TODO
* Проверка наличия всех девайсов (камер)
* По команде прервать запись с определенной камеры и начать заново (это нужно чтобы вытащить кадр из текущего кусочка записи)
* Состояние системы (свободное место на винте, время работы с момента последней перезагрузки и тп) – тоже в конфиге как-то хранить
* Слежение за свободным местом на диске (например записи с камер 1 и 2 должны хранится 12 часов, но все вместе не более 15Гб)
* Алерты об ошибках в Приложение1
* Запуск Приложения3 – при появлении файлов с определенной камеры надо запускать нашу программку (Приложение2), потом файлик удалять (или не удалять – параметр в конфиге)