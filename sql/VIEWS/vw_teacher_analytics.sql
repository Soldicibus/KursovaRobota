CREATE OR REPLACE VIEW vw_teacher_analytics AS
WITH LessonCounts AS (
    SELECT 
        lesson_teacher, 
        COUNT(*) as lessons_conducted,
        MAX(lesson_date) as last_lesson
    FROM Lessons 
    GROUP BY lesson_teacher
),
GradingStats AS (
    -- How many marks did this teacher give? Are they active?
    SELECT 
        l.lesson_teacher,
        COUNT(sd.mark) as marks_given,
        ROUND(AVG(sd.mark), 2) as avg_mark_given -- Is the teacher strict?
    FROM StudentData sd
    JOIN Lessons l ON sd.lesson = l.lesson_id
    GROUP BY l.lesson_teacher
)
SELECT 
    t.teacher_surname,
    t.teacher_name,
	t.teacher_patronym,
    sub.subject_name,
    COALESCE(lc.lessons_conducted, 0) as total_lessons,
    COALESCE(gs.marks_given, 0) as total_marks_assigned,
    gs.avg_mark_given as strictness_factor, -- Lower = Stricter
    CURRENT_DATE - lc.last_lesson as days_since_last_lesson
FROM Teacher t
LEFT JOIN LessonCounts lc ON t.teacher_id = lc.lesson_teacher
LEFT JOIN GradingStats gs ON t.teacher_id = gs.lesson_teacher
LEFT JOIN Subjects sub ON t.teacher_id = (SELECT lesson_teacher FROM Lessons WHERE lesson_teacher = t.teacher_id LIMIT 1); -- Simplified join for subject