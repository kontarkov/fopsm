# Домашнее задание 7.2 — Terraform

## Содержание

1. [Задание](#1-задание)
2. [Подготовка окружения](#2-подготовка-окружения)
3. [Конфигурация Terraform](#3-конфигурация-terraform)
4. [Создание и проверка контейнеров](#4-создание-и-проверка-контейнеров)
5. [Дополнительные ресурсы и Terraform State](#5-дополнительные-ресурсы-и-terraform-state)
6. [Проверка configuration drift](#6-проверка-configuration-drift)
7. [Результат](#7-результат)

## 1. Задание

Нужно установить Terraform и повторить демонстрацию из лекции. Работа выполнена на виртуальной машине с Ubuntu Server и Docker. Конфигурация находится в файлах `providers.tf`, `variables.tf` и `main.tf` рядом с отчётом.

## 2. Подготовка окружения

Использована Ubuntu Server 24.04.4 LTS в Parallels Desktop. Подключение к виртуальной машине выполнено через VS Code Remote-SSH.

Установлен Terraform 1.17.0. Docker Engine был настроен заранее и доступен обычному пользователю. Для контейнеров использован провайдер `kreuzwerker/docker` версии 4.6.0.

Рабочий каталог инициализирован, конфигурация отформатирована и проверена:

```bash
terraform init
terraform fmt
terraform validate
```

Инициализация прошла успешно, проверка конфигурации ошибок не обнаружила.

![Инициализация Terraform](images/02_terraform_init.png)

![Проверка конфигурации](images/03_terraform_validate.png)

## 3. Конфигурация Terraform

В `variables.tf` заданы параметры двух контейнеров: Nginx и WordPress. В `main.tf` описано создание Docker-образов и контейнеров.

Использованные образы:

- `nginx:1.21.1`;
- `wordpress:latest`.

Оба порта опубликованы на `127.0.0.1` виртуальной машины: Nginx — `1080`, WordPress — `2080`. Так они не открыты напрямую для всей сети.

Сначала выполнена команда:

```bash
terraform plan
```

Terraform сформировал план создания ресурсов. После проверки плана выполнен `terraform apply` с подтверждением.

![План создания Nginx](images/04a_terraform_plan_nginx.png)

![План создания WordPress](images/04b_terraform_plan_wordpress.png)

![Итог первоначального плана](images/04c_terraform_plan_summary.png)

После уточнения адреса публикации портов проверена привязка к `127.0.0.1`.

![План с привязкой к localhost](images/04d_terraform_plan_localhost_summary.png)

![Подтверждение применения](images/05a_terraform_apply_confirmation.png)

![Итог создания ресурсов](images/05d_terraform_apply_result.png)

## 4. Создание и проверка контейнеров

После применения конфигурации состояние контейнеров проверено командой:

```bash
docker ps
```

Оба контейнера успешно запущены. Проверка HTTP показала: Nginx — `200 OK`, WordPress — перенаправление на первоначальную страницу настройки (`302`). База данных WordPress не настраивалась, поскольку для демонстрации запуска контейнера она не требовалась.

![Контейнеры Docker](images/06_docker_containers.png)

![Проверка веб-сервисов](images/07_services_check.png)

Для просмотра страниц в браузере Mac настроены SSH-туннели. Страница Nginx открылась, WordPress показал мастер начальной настройки.

![Страница Nginx](images/08_nginx_browser_mac.png)

![Страница WordPress](images/09_wordpress_browser_mac.png)

## 5. Дополнительные ресурсы и Terraform State

Через `terraform console` просмотрены значения `var.containers` и параметры отдельных контейнеров.

![Terraform console](images/10_terraform_console.png)

Добавлен ресурс `random_password.any_uniq_name` длиной 16 символов. Для него подключён провайдер `hashicorp/random`. Затем выполнены `terraform init`, `terraform plan` и `terraform apply`.

![Инициализация провайдера random](images/11_terraform_init_random_provider.png)

![План создания random_password](images/12_terraform_plan_random_password.png)

![Создание random_password](images/13_terraform_apply_random_password.png)

Добавлен ресурс `local_file.xxx`, записывающий демонстрационную строку в `/tmp/xxx.txt`. Права файла установлены `0600`. Подключён провайдер `hashicorp/local`, после чего применена конфигурация.

![Инициализация local provider](images/14_terraform_init_local_provider.png)

После первоначального плана права нового файла изменены с `0777` на `0600`.

![Итоговый план local_file с правами 0600](images/15b_terraform_plan_local_file_0600.png)

![Создание local_file](images/16_terraform_apply_local_file.png)

После создания файла командой `stat` проверены метаданные: владелец `devlab`, права `600`, размер 33 байта. Значение пароля не выводилось.

![Проверка прав и размера файла](images/17_terraform_local_file_permissions.png)

Команда `terraform state list` показала шесть ресурсов: два образа, два контейнера, `random_password` и `local_file`.

![Список ресурсов Terraform State](images/18_terraform_state_list.png)

## 6. Проверка configuration drift

Проверена реакция Terraform на ручное изменение инфраструктуры. Исходное имя контейнера Nginx — `our-cool-project-reverse-proxy-nginx`. Затем контейнер переименован напрямую через Docker:

```bash
docker rename our-cool-project-reverse-proxy-nginx nginx-manually-renamed
```

При этом контейнер остался в состоянии `running`.

![Ручное переименование Nginx](images/19_terraform_drift_docker_rename.png)

Следующий `terraform plan` обнаружил разницу с конфигурацией. Для возврата исходного имени Terraform предложил **заменить** контейнер, а не переименовать его на месте:

```text
Plan: 1 to add, 0 to change, 1 to destroy.
```

![Terraform обнаружил drift и предложил замену](images/20_terraform_drift_plan.png)

После `terraform apply` старый контейнер удалён и создан новый. Проверка показала: исходное имя `our-cool-project-reverse-proxy-nginx` восстановлено, состояние — `running`, HTTP-ответ Nginx — `200`.

![Пересоздание Nginx через Terraform](images/21b_terraform_drift_recovery_apply.png)

![Проверка контейнера и HTTP после восстановления](images/22_terraform_drift_recovery_validation.png)

Финальная команда `terraform plan` показала:

```text
No changes. Your infrastructure matches the configuration.
```

![Финальный план Terraform без изменений](images/23_terraform_plan_no_changes.png)

## 7. Результат

Terraform установлен, демонстрация из лекции повторена. Созданы и проверены контейнеры Nginx и WordPress. Выполнены упражнения с `terraform console`, `random_password`, `local_file` и Terraform State. Проверено обнаружение ручных изменений и восстановление конфигурации через Terraform.

Для подготовки к отправке проверен состав файлов и создан `.gitignore`. Файлы `terraform.tfstate`, `terraform.tfstate.backup` и каталог `.terraform/` не предназначены для загрузки в репозиторий.

![Файлы проекта перед подготовкой к GitHub](images/24_terraform_project_files_before_gitignore.png)

![Файл gitignore](images/25_terraform_gitignore.png)
