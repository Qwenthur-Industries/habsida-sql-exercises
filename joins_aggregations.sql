-- 1. Кто что заказал
SELECT o.id AS order_id, u.email, p.name, o.quantity
FROM orders AS o
JOIN users AS u ON o.user_id = u.id
JOIN products AS p ON o.product_id = p.id;

-- 2. Сортировка по дню заказа
SELECT o.id AS order_id, u.email, p.name,
       o.quantity, DATE(o.created_at) AS order_date
FROM orders AS o
JOIN users AS u ON o.user_id = u.id
JOIN products AS p ON o.product_id = p.id
ORDER BY order_date ASC, o.id ASC;

-- 3. Пользователи без заказов
SELECT u.email
FROM users AS u
LEFT JOIN orders AS o ON u.id = o.user_id
WHERE o.id IS NULL;

-- 4. Заказы по статусам
SELECT status, COUNT(*) AS order_count
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- 5. Выручка по категориям
SELECT p.category, SUM(p.price * o.quantity) AS total_revenue
FROM orders AS o
JOIN products AS p ON o.product_id = p.id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 6. Топ-5 покупателей
SELECT u.email, SUM(o.quantity) AS total_items
FROM users AS u
JOIN orders AS o ON u.id = o.user_id
GROUP BY u.id, u.email
ORDER BY total_items DESC
LIMIT 5;

-- 7. Категории выше среднего
SELECT category, AVG(price) AS average_price
FROM products
GROUP BY category
HAVING AVG(price) > (
    SELECT AVG(price) FROM products
);

-- 8. Частые покупатели
SELECT u.email, COUNT(o.id) AS order_count
FROM users AS u
JOIN orders AS o ON u.id = o.user_id
GROUP BY u.id, u.email
HAVING COUNT(o.id) > 40
ORDER BY order_count DESC;

-- 9. Никогда не заказанные товары
SELECT p.name
FROM products AS p
LEFT JOIN orders AS o ON p.id = o.product_id
WHERE o.id IS NULL;
