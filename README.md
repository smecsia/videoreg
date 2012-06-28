# Changelog

## 28.06.2012
### Current status
* Запуск видеозаписи
    * Параметры для всех камер хранятся в одном конфиге (разрешение, фпс, длительность каждого файла)
    * Запись по кускам (по 10минут в один файл например)
    * Слежение

### TODO
* Наличие всех девайсов (камер)
* По команде прервать запись с определенной камеры и начать заново (это нужно чтобы вытащить кадр из текущего кусочка записи)
* Состояние системы (свободное место на винте, время работы с момента последней перезагрузки и тп) – тоже в конфиге как-то хранить
* Слежение за свободным местом на диске (например записи с камер 1 и 2 должны хранится 12 часов, но все вместе не более 15Гб)
* Алерты об ошибках в Приложение1
* Запуск Приложения3 – при появлении файлов с определенной камеры надо запускать нашу программку (Приложение2), потом файлик удалять (или не удалять – параметр в конфиге)