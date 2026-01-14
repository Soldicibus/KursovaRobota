CREATE OR REPLACE FUNCTION translit_uk_to_lat(p_text TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    t TEXT;
BEGIN
    t := lower(p_text);

    -- Multi-letter replacements first
    t := replace(t, 'щ', 'shch');
    t := replace(t, 'ж', 'zh');
    t := replace(t, 'ч', 'ch');
    t := replace(t, 'ш', 'sh');
    t := replace(t, 'ю', 'yu');
    t := replace(t, 'я', 'ya');
    t := replace(t, 'є', 'ye');
    t := replace(t, 'ї', 'yi');
    t := replace(t, 'х', 'kh');
    t := replace(t, 'ц', 'ts');

    -- Single-letter mapping
    t := translate(
        t,
        'абвгґдеиіїйклмнопрстуфзь',
        'abvhgdeyiyiklmnoprstufz'
    );

    RETURN t;
END;
$$;
