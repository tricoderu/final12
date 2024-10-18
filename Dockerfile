# Были большие проблемы с образом в Windows: сначала не видел файл go.mod, потом не создавал myapp
# Поэтому полно комментариев

# Устанавливаем базовый образ
FROM golang:1.23.2 AS builder

# Сначала проверим, что файлы вообще есть и они живые
# RUN ls -la go.mod
# ERROR [builder  2/15] RUN ls -la go.mod
RUN if [ -f go.mod ]; then echo "go.mod exists"; else echo "go.mod doesn't exist"; fi

# RUN ls -la go.sum
# ERROR [builder  3/11] RUN ls -la go.sum 
RUN if [ -f go.sum ]; then echo "go.sum exists"; else echo "go.sum doesn't exist"; fi

# Устанавливаем рабочую директорию
# НЕ СРАБОТАЛО по неизвестной причине: WORKDIR /dev
WORKDIR /app

# Копируем go.mod и go.sum в контейнер
COPY go.mod go.sum ./
# COPY ./go.mod ./go.sum ./

# Проверяем аналогично (так как с этим были проблемы), что все скопировалось и все живое
# Использую полный путь на всякий случай
RUN ls -la /app/go.mod
# RUN cat go.mod

RUN ls -la /app/go.sum
# RUN cat go.sum

# Загружаем зависимости для кэширования слоев сборки
RUN go mod download

# Копируем весь код приложения
COPY . .

# УБРАЛ из-за избыточности: Лишний раз используем переменные окружения и проверим, что файл на правильной архитектуре
# RUN GOOS=linux GOARCH=amd64 go build -o myapp .

# ПРОСТО СОБЕРЕМ ОБРАЗ
RUN go build -o myapp .

# Проверяем:
# - наличие директории app
# - наличие файла myapp перед копированием
# - задаем myapp полные права
# - проверяем, что myapp исполняемый
RUN ls -la /app && \
    ls -la myapp && \
    chmod +x myapp && \
    stat myapp

# Используем образ ALPINE для запуска приложения
FROM alpine:latest

# Переносим собранное приложение в новый образ из этапа сборки
# НЕ СРАБОТАЛО: WORKDIR /app
WORKDIR /root
# НЕ СРАБОТАЛО: COPY --from=builder /dev/myapp .
COPY --from=builder /app/myapp .
# И по аналогии
RUN ls -la myapp && stat myapp

# СКРЫЛ: # НА бущуее устанавливаем ca-certificates, если приложение будет делать HTTP-запросы
# СКРЫЛ: # RUN apk add --no-cache ca-certificates

# СКРЫЛ: На будущее, даже если контейнер запущен с флагом -p, пусть другие знают, какой порт прослушивается.
# То есть на случай docker run -p 8080:8080 myapp
# СКРЫЛ: Открываем порт
# СКРЫЛ: EXPOSE 8080

# Указываем, какую команду выполнять в контейнере
CMD ["./myapp"]