CREATE OR REPLACE FUNCTION get_children_by_parent(
    p_parent_id INT
)
RETURNS TABLE(
    student_name VARCHAR,
    student_surname VARCHAR,
    student_class VARCHAR,
    avg_grade NUMERIC(4,2),
    attendance NUMERIC(5,2)
)
LANGUAGE sql
AS $$
    SELECT
        s.student_name,
        s.student_surname,
        s.student_class,

        ROUND(AVG(j.mark)::NUMERIC, 2) AS avg_grade,

        ROUND(
            100.0 * COUNT(*) FILTER (WHERE j.status = 'Присутній' OR j.status = 'П')
            / NULLIF(COUNT(*), 0),
            2
        ) AS attendance

    FROM StudentParent sp
    JOIN Students s ON sp.student_id_ref = s.student_id
    LEFT JOIN StudentData j ON j.student_id = s.student_id

    WHERE sp.parent_id_ref = p_parent_id

    GROUP BY s.student_id, s.student_name, s.student_surname, s.student_class;
$$;
