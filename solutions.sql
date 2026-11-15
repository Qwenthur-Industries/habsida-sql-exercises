-- Задание 1. Все администраторы

SELECT email, full_name
FROM users
WHERE role = 'admin';

-- Задание 2. Доступная электроника

SELECT name, price
FROM products
WHERE category = 'Electronics'
  AND price < 50
ORDER BY price ASC;

-- Задание 3. Самые новые аккаунты

SELECT email, created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- Задание 4. Только клавиатуры

SELECT name, category, price
FROM products
WHERE name LIKE '%Keyboard%'
ORDER BY name ASC;

-- Задание 5. Имена, начинающиеся с A

SELECT full_name, email
FROM users
WHERE full_name LIKE 'A%';

-- Задание 6. Самая дешёвая мебель

SELECT name, price
FROM products
WHERE category = 'Furniture'
ORDER BY price ASC
LIMIT 5;

-- Задание 7. Средний ценовой диапазон

SELECT name, category, price
FROM products
WHERE price BETWEEN 100 AND 200
ORDER BY price DESC
LIMIT 10;

-- Задание 8. Вторая страница дорогих товаров

SELECT name, price
FROM products
ORDER BY price DESC, id ASC
LIMIT 5 OFFSET 5;

-- Задание 9. Первичный и внешний ключи
-- orders.user_id ссылается на users.id
-- users.id первичный ключ так как он уникален для каждого пользователя