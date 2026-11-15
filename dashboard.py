import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

load_dotenv()

def get_engine():
    """Создаёт подключение к PostgreSQL."""
    url = os.getenv("DATABASE_URL")

    if not url:
        raise ValueError("DATABASE_URL не найден в .env")

    engine = create_engine(url, pool_pre_ping=True)

    # Проверяем реальное соединение с базой
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))

    return engine

def store_report(engine):
    """Выводит статистику магазина."""
    with engine.connect() as conn:
        users = conn.execute(
            text("SELECT COUNT(*) FROM users")
        ).scalar_one()

        products = conn.execute(
            text("SELECT COUNT(*) FROM products")
        ).scalar_one()

        orders = conn.execute(
            text("SELECT COUNT(*) FROM orders")
        ).scalar_one()

        print("\n=== Store Dashboard ===")
        print(f"Users: {users} | Products: {products} | Orders: {orders}")

        catalog = conn.execute(
            text("""
                SELECT name, price, stock
                FROM products
                ORDER BY name
            """)
        ).fetchall()

        print("\nCatalog:")
        for product in catalog:
            print(
                f"  {product.name:<30} "
                f"${product.price:>8.2f} "
                f"(stock {product.stock})"
            )

        top_customers = conn.execute(
            text("""
                SELECT
                    u.email,
                    SUM(o.quantity) AS total_items
                FROM users AS u
                JOIN orders AS o ON o.user_id = u.id
                GROUP BY u.id, u.email
                ORDER BY total_items DESC, u.email
                LIMIT 3
            """)
        ).fetchall()

        print("\nTop customers:")
        for customer in top_customers:
            print(
                f"  {customer.email:<35} "
                f"- {customer.total_items} items"
            )

        low_stock = conn.execute(
            text("""
                SELECT name, stock
                FROM products
                WHERE stock < 10
                ORDER BY stock ASC, name
            """)
        ).fetchall()

        print("\nLow stock products:")
        if low_stock:
            for product in low_stock:
                print(f"  {product.name} - {product.stock} left")
        else:
            print("  All products have sufficient stock.")

        revenue = conn.execute(
            text("""
                SELECT
                    p.name,
                    COALESCE(
                        SUM(p.price * o.quantity), 0
                    ) AS total_revenue
                FROM products AS p
                LEFT JOIN orders AS o
                    ON o.product_id = p.id
                GROUP BY p.id, p.name
                ORDER BY total_revenue DESC, p.name
            """)
        ).fetchall()

        print("\nRevenue by product:")
        for product in revenue:
            print(
                f"  {product.name:<30} "
                f"${product.total_revenue:>12,.2f}"
            )
        
        users_without_orders = conn.execute(
            text("""
                SELECT u.email
                FROM users AS u
                LEFT JOIN orders AS o
                    ON o.user_id = u.id
                WHERE o.id IS NULL
                ORDER BY u.email
            """)
        ).fetchall()

        print("\nUsers without orders:")
        if users_without_orders:
            for user in users_without_orders:
                print(f"  {user.email}")
        else:
            print("  Every user has at least one order.")

def add_product(engine, name, category, price, stock):
    """Добавляет товар и возвращает его id."""
    with engine.begin() as conn:
        new_id = conn.execute(
            text("""
                INSERT INTO products (name, category, price, stock)
                VALUES (:name, :category, :price, :stock)
                RETURNING id
            """),
            {
                "name": name,
                "category": category,
                "price": price,
                "stock": stock,
            },
        ).scalar_one()

    return new_id

def place_order(engine, email, product_name, quantity):
    """Создаёт заказ и безопасно уменьшает остаток."""
    if not 1 <= quantity <= 10:
        raise ValueError("Количество должно быть от 1 до 10")

    with engine.begin() as conn:
        user = conn.execute(
            text("SELECT id FROM users WHERE email = :email"),
            {"email": email},
        ).first()

        if user is None:
            raise ValueError("Пользователь не найден")

        product = conn.execute(
            text("""
                SELECT id, stock
                FROM products
                WHERE name = :name
                FOR UPDATE
            """),
            {"name": product_name},
        ).first()

        if product is None:
            raise ValueError("Товар не найден")

        if product.stock < quantity:
            raise ValueError(
                f"Недостаточно товара. Доступно: {product.stock}"
            )

        order_id = conn.execute(
            text("""
                INSERT INTO orders (user_id, product_id, quantity)
                VALUES (:user_id, :product_id, :quantity)
                RETURNING id
            """),
            {
                "user_id": user.id,
                "product_id": product.id,
                "quantity": quantity,
            },
        ).scalar_one()

        conn.execute(
            text("""
                UPDATE products
                SET stock = stock - :quantity
                WHERE id = :product_id
            """),
            {
                "quantity": quantity,
                "product_id": product.id,
            },
        )

    return order_id

def main():
    try:
        engine = get_engine()
        print("Подключение к PostgreSQL успешно!")

        while True:
            print("\n=== Store Menu ===")
            print("1. Показать отчёт магазина")
            print("2. Добавить товар")
            print("3. Оформить заказ")
            print("0. Выход")

            choice = input("\nВыберите действие: ").strip()

            if choice == "1":
                store_report(engine)

            elif choice == "2":
                try:
                    name = input("Название товара: ").strip()
                    category = input("Категория: ").strip()
                    price = input("Цена: ").strip()
                    stock = input("Количество на складе: ").strip()

                    if not name or not category:
                        raise ValueError("Название и категория обязательны")

                    from decimal import Decimal

                    price = Decimal(price)
                    stock = int(stock)

                    if not price.is_finite() or price < 0 or stock < 0:
                        raise ValueError("Цена и остаток не могут быть отрицательными")

                    new_id = add_product(
                        engine, name, category, price, stock
                    )
                    print(f"Товар успешно добавлен! ID: {new_id}")

                except (ValueError, SQLAlchemyError) as error:
                    print(f"Ошибка добавления товара: {error}")

            
            elif choice == "3":
                try:
                    email = input("Email покупателя: ").strip()
                    product_name = input("Название товара: ").strip()
                    quantity = int(input("Количество: ").strip())

                    order_id = place_order(
                        engine, email, product_name, quantity
                    )

                    print(f"Заказ успешно оформлен! ID: {order_id}")

                except (ValueError, SQLAlchemyError) as error:
                    print(f"Ошибка оформления заказа: {error}")


            elif choice == "0":
                print("До встречи!")
                break

            else:
                print("Неизвестная команда")

    except (SQLAlchemyError, ValueError) as error:
        print(f"Ошибка подключения: {error}")

if __name__ == "__main__":
    main()
