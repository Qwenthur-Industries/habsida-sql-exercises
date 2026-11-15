-- 1. Создание таблицы студентов
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    birth_date DATE,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 2. Создание таблицы курсов
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name TEXT NOT NULL,
    instructor TEXT NOT NULL,
    credits INTEGER NOT NULL CHECK (credits > 0)
);

-- 3. Создание таблицы оценок
CREATE TABLE grades (
    grade_id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES students(student_id),
    course_id INTEGER NOT NULL REFERENCES courses(course_id),
    grade NUMERIC(5, 2) NOT NULL CHECK (grade BETWEEN 0 AND 100),
    UNIQUE (student_id, course_id)
);

-- 4. Добавление трёх курсов
INSERT INTO courses (course_name, instructor, credits)
VALUES
    ('Databases', 'Alex Kim', 4),
    ('Statistics', 'Sarah Lee', 3),
    ('Algorithms', 'David Park', 5);

-- 5. Добавление трёх студентов
INSERT INTO students (full_name, email, birth_date)
VALUES
    ('Alex Johnson', 'alex.johnson@example.com', '2002-05-15'),
    ('Emma Wilson', 'emma.wilson@example.com', '2003-08-22'),
    ('Daniel Brown', 'daniel.brown@example.com', NULL);

-- 6. Добавление четырёх оценок
INSERT INTO grades (student_id, course_id, grade)
VALUES
    (1, 1, 95),
    (1, 2, 88),
    (2, 1, 91),
    (2, 3, 84);

-- 7. Обновление email
UPDATE students
SET email = 'alex.johnson2026@example.com'
WHERE student_id = 1;

-- 8. Обновление даты рождения
UPDATE students
SET birth_date = '2004-03-12'
WHERE student_id = 3;

-- 9. Удаление студента без оценок
DELETE FROM students
WHERE student_id = 3;

-- 10. Проверка результатов
SELECT * FROM students;
SELECT * FROM courses;

SELECT s.full_name, c.course_name, g.grade
FROM grades AS g
JOIN students AS s ON s.student_id = g.student_id
JOIN courses AS c ON c.course_id = g.course_id
ORDER BY s.student_id, c.course_id;