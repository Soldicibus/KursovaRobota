-- Тригер для автоматичного перепризначення уроків при видаленні вчителя
-- Мета: Зберегти історію уроків, передавши їх іншому вчителю (наприклад, "заміні").

CREATE OR REPLACE FUNCTION reassign_lessons_on_teacher_delete()
RETURNS TRIGGER AS $$
DECLARE
    fallback_teacher_id INT;
BEGIN
    -- Перевіряємо, чи є у вчителя уроки
    IF EXISTS (SELECT 1 FROM Lessons WHERE lesson_teacher = OLD.teacher_id) THEN
        
        -- Спроба знайти вчителя для заміни.
        -- Логіка: Шукаємо класного керівника класу, де проводився урок? 
        -- Для простоти беремо першого доступного вчителя, який НЕ видаляється.
        SELECT teacher_id INTO fallback_teacher_id 
        FROM Teacher 
        WHERE teacher_id <> OLD.teacher_id 
        ORDER BY teacher_id ASC 
        LIMIT 1;

        -- Якщо іншого вчителя не знайдено (наприклад, це був єдиний вчитель)
        IF fallback_teacher_id IS NULL THEN
            RAISE EXCEPTION 'Неможливо видалити вчителя (id=%), оскільки він має уроки, і немає іншого вчителя для їх автоматичної передачі.', OLD.teacher_id;
        END IF;

        -- Переносимо всі уроки видаленого вчителя на знайденого "замісника"
        UPDATE Lessons 
        SET lesson_teacher = fallback_teacher_id 
        WHERE lesson_teacher = OLD.teacher_id;

        RAISE NOTICE 'Вчитель (id=%) видаляється. Його уроки (% шт.) були автоматично передані вчителю (id=%).', OLD.teacher_id, (SELECT count(*) FROM Lessons WHERE lesson_teacher = fallback_teacher_id), fallback_teacher_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_teacher_delete_reassign_lessons ON Teacher;

CREATE TRIGGER trg_teacher_delete_reassign_lessons
BEFORE DELETE ON Teacher
FOR EACH ROW
EXECUTE FUNCTION reassign_lessons_on_teacher_delete();
