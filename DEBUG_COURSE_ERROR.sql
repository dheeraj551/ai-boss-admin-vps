-- ================================================
-- DEBUG COURSE CREATION ERROR
-- ================================================

-- 1. Check exact RLS status on courses table
SELECT 
    c.relname as table_name,
    c.relrowsecurity as rls_enabled,
    c.relforcerowsecurity as rls_forced
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid  
WHERE n.nspname = 'public' AND c.relname = 'courses';

-- 2. Check all policies on courses table
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'courses'
ORDER BY policyname;

-- 3. Try to insert with detailed error reporting
DO $$
DECLARE
    course_result UUID;
    error_msg TEXT;
BEGIN
    BEGIN
        INSERT INTO public.courses (
            title, description, subject, level, duration_weeks, created_by
        ) VALUES (
            'Debug Test Course',
            'Testing course creation step by step',
            'Debug',
            'beginner',
            '1', 
            'debug'
        ) RETURNING id INTO course_result;
        
        RAISE NOTICE 'SUCCESS: Course created with ID: %', course_result;
        
        -- Clean up
        DELETE FROM public.courses WHERE id = course_result;
        RAISE NOTICE 'Test course deleted successfully';
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        RAISE NOTICE 'COURSE INSERT FAILED: %', error_msg;
        RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
        
        -- Also check what columns actually exist
        RAISE NOTICE 'Trying to check table structure...';
    END;
END $$;

-- 4. Check actual table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'courses'
ORDER BY ordinal_position;