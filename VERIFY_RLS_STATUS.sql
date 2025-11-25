-- ================================================
-- RLS STATUS VERIFICATION SCRIPT
-- ================================================

-- 1. Check which tables exist and their RLS status
SELECT 
    c.relname as table_name,
    CASE 
        WHEN c.relrowsecurity THEN 'RLS ENABLED ❌'
        ELSE 'RLS DISABLED ✅'
    END as rls_status,
    CASE 
        WHEN c.relrowsecurity THEN 'Fix needed: RLS still enabled'
        ELSE 'Schema ready: All tables created with RLS disabled'
    END as status_message
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' AND c.relname IN (
    'blog_posts', 'courses', 'course_modules', 'course_topics', 
    'testimonials', 'jobs', 'instagram_posts'
)
ORDER BY c.relname;

-- 2. Check for any existing policies on courses table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN (
    'blog_posts', 'courses', 'course_modules', 'course_topics', 
    'testimonials', 'jobs', 'instagram_posts'
)
ORDER BY tablename, policyname;

-- 3. Check all policies on courses table specifically
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'courses'
ORDER BY policyname;