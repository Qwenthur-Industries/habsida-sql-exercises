-- Задание 1. Создание таблицы отзывов

CREATE TABLE reviews (
    user_id INTEGER NOT NULL REFERENCES users(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, product_id)
);

-- Задание 2. Добавление номера телефона

ALTER TABLE users
ADD COLUMN phone_number TEXT;

-- Задание 3. Ограничение количества товаров

ALTER TABLE orders
ADD CONSTRAINT quantity_max_10
CHECK (quantity <= 10);

-- Задание 4. Добавление нового товара

INSERT INTO products (name, category, price, stock)
VALUES ('Studio Desk Lamp', 'Office', 45.50, 25)
RETURNING id;

-- Результат: id = 202

-- Задание 5. Повышение цен на мебель

UPDATE products
SET price = price * 1.10
WHERE category = 'Furniture';

-- Обновлены цены 39 товаров.

-- Задание 6. Отмена устаревших заказов

UPDATE orders
SET status = 'cancelled'
WHERE status = 'pending'
  AND created_at < now() - INTERVAL '30 days';

-- Задание 7. Проверка внешнего ключа

-- Товар id = 102 встречается в 184 заказах.

-- Выполненная попытка удаления:
-- DELETE FROM products WHERE id = 102;

-- Ошибка SQLSTATE 23503:
-- Нарушение ограничения orders_product_id_fkey.
-- Товар нельзя удалить, поскольку на него
-- ссылаются существующие заказы.

-- Задание 8. Создание индекса

CREATE INDEX idx_orders_status_created_at
ON orders (status, created_at);

-- Задание 9. Транзакция заказа

-- Перед выполнением проверяем текущий остаток товара.

BEGIN;

WITH updated_stock AS (
    UPDATE products
    SET stock = stock - 2
    WHERE id = 1 AND stock >= 2
    RETURNING id
)
INSERT INTO orders (user_id, product_id, quantity)
SELECT 1, id, 2
FROM updated_stock
RETURNING id, user_id, product_id, quantity;

COMMIT;


-- Результат:
-- Если stock >= 2, остаток уменьшается на 2 и создаётся заказ.
-- Если stock < 2, заказ не создаётся.
-- RETURNING показывает результат вставки.
-- Обе операции выполняются в одной транзакции.
-- В обеих операциях ошибок не возникло.
-- При ошибке внутри транзакции используется ROLLBACK.