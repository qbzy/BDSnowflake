# BigDataSnowflake

Лабораторная работа: нормализация исходных CSV-данных в аналитическую модель типа снежинка.

## Состав результата

- `docker-compose.yml` запускает PostgreSQL 16 и автоматически выполняет SQL-скрипты из `sql`.
- `исходные данные/` содержит 10 CSV-файлов по 1000 записей.
- `sql/01_ddl.sql` создает staging-слой и DWH-таблицы фактов и измерений.
- `sql/02_dml_load_staging.sql` загружает все CSV в `staging.mock_data`.
- `sql/03_dml_transform.sql` заполняет измерения и факт продаж.
- `sql/04_checks.sql` содержит проверочные и аналитические запросы.

## Запуск

```bash
docker compose up -d
```

Подключение:

- host: `localhost`
- port: `5432`
- database: `bdsnowflake`
- user: `postgres`
- password: `postgres`

При первом запуске контейнер создаст таблицы, загрузит 10000 строк в `staging.mock_data` и построит витрину `dwh`.

Для повторной полной инициализации удалите volume и запустите контейнер снова:

```bash
docker compose down -v
docker compose up -d
```

## Модель

Факт: `dwh.fact_sales`.

Измерения:

- `dwh.dim_customer`
- `dwh.dim_seller`
- `dwh.dim_product`
- `dwh.dim_store`
- `dwh.dim_supplier`
- `dwh.dim_date`
- справочники снежинки: страны, типы питомцев, категории питомцев, категории товаров, бренды и материалы товаров.

Проверка результата:

```sql
SELECT COUNT(*) FROM staging.mock_data;
SELECT COUNT(*) FROM dwh.fact_sales;
```

Оба запроса должны вернуть `10000`.
