# template-java-service

Шаблон репозиторію для Java-сервіса Kite: Spring Boot 3, Java 21, образ у GHCR,
CI з одного рядка. Із нього створюються 12 Java-сервісів (5.6).

## Новий сервіс

```bash
gh repo create kite-post/shipment-service --public --template kite-post/template-java-service
cd shipment-service
make rename NAME=shipment-service
git add -A && git commit -m "Перейменувати шаблон у shipment-service" && git push
```

`make rename` перейменовує артефакт, пакет (`ua.kite.servicetemplate` →
`ua.kite.shipment`), клас застосунку та ім'я образу. Без нього репозиторій теж
збирається і проходить CI — просто під іменем шаблону.

## Що всередині

```
pom.xml                   Spring Boot 3.5, Java 21, Spotless, Failsafe
src/main/java             застосунок і один ендпоїнт /api/v1/info
src/main/resources        application.yml: actuator, Prometheus, graceful shutdown
src/test/java             тест контексту + інтеграційний тест на справжньому порту
Dockerfile                шарований образ Spring Boot на temurin-21-jre-alpine
Makefile                  той самий набір цілей, що й у решти репозиторіїв
.github/workflows/ci.yml  п'ять рядків: виклик спільного workflow із .github
```

## Команди

```bash
make build      # зібрати jar
make lint       # формат і імпорти (Spotless + palantir-java-format)
make fmt        # відформатувати
make test       # юніт-тести
make test-it    # разом з інтеграційними (*IT)
make verify     # усе, що робить CI
make image      # зібрати образ локально
make up         # підняти образ на 8080 з лімітом 384 МБ
make run        # запустити з Maven, без контейнера
```

## CI

Увесь пайплайн — виклик спільного workflow з
[kite-post/.github](https://github.com/kite-post/.github): лінт, тести,
збірка образу, публікація в `ghcr.io/kite-post/<сервіс>` і PR у `kite-infra`,
який піднімає версію у `versions.env` (12.6).

На pull request образ збирається, але не публікується. Теги: `sha-<хеш>` для
`main`, `v<semver>` для релізів; рухомого `latest` немає принципово.

## Коли з'явиться база

1. Додати `spring-boot-starter-data-jpa` і `org.postgresql:postgresql`.
2. Міграції — Flyway у `src/main/resources/db/migration`; сервіс застосовує їх
   сам на старті (12.3).
3. В інтеграційному тесті підняти Postgres контейнером — Testcontainers уже в
   залежностях, приклад є в коментарі `InfoEndpointIT`.

## Контракти

Моделі API, інтерфейси контролерів і класи подій CloudEvents приходять
залежністю `ua.kite:kite-contracts`, закріпленою за тегом — своїх копій
`openapi.yaml` і JSON Schema сервіс не тримає (5.4, п. 6):

```xml
<kite-contracts.version>0.1.0</kite-contracts.version>
```

```bash
make contracts            # підтягнути пакет за поточним тегом
make contracts V=0.3.0    # перейти на нову версію: Makefile + pom.xml
make contracts-check      # версія закріплена, копій схем немає, залежність резолвиться
```

Нова версія приходить сама: після релізу `kite-contracts` розсилає подію
всім репозиторіям із топіком `kite-contracts`, і workflow `contracts-bump`
відкриває PR з `make contracts V=<версія>`. Версія одна на всі репозиторії.
Руками те саме: `make contracts V=0.3.0`. Якщо тегу немає, `Makefile` і
маніфест лишаються як були.

`contracts-check` проганяє спільний CI. Самі схеми лежать у тому самому jar
(`/kite/contracts/openapi`, `/kite/contracts/events`), тож валідація події не
потребує копії файла в репозиторії — так це і перевіряє `ContractsWiringTest`.

Пакет живе в GitHub Packages, а він віддає Maven лише з токеном. У CI
`settings.xml` розставляє спільний workflow; локально потрібен свій:

```xml
<!-- ~/.m2/settings.xml -->
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>ВАШ-ЛОГІН</username>
      <password>ghp_… (scope read:packages)</password>
    </server>
  </servers>
</settings>
```

Порядок наскрізної зміни (5.6): спершу адитивна зміна в `kite-contracts` з
новим тегом, потім версія тут, і тільки потім продюсер починає слати нове
поле.

## Коли з'являться події

Писати подію треба в одній транзакції зі зміною, у таблицю `outbox`; окремий
процес публікує її в Kafka. Споживач тримає `processed_event(event_id)` і
пропускає повтори. Класи подій і реєстр топіків уже є в `kite-contracts`:
`ua.kite.contracts.model.ShipmentStatusChangedEvent`, `KiteEventType`.
