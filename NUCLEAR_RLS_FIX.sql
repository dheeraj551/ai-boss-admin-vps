-- ================================================
-- NUCLEAR RLS FIX - DROPS ALL POLICIES THEN DISABLES RLS
-- ================================================

-- ================================================
-- WARNING: THIS WILL DROP ALL EXISTING RLS POLICIES
-- Run this ONLY if VERIFY_RLS_STATUS shows RLS still enabled
-- ================================================

-- ================================================
-- STEP 1: DROP ALL EXISTING POLICIES ON ALL TABLES
-- ================================================

-- Drop ALL policies on blog_posts
DROP POLICY IF EXISTS "All operations for blog_posts" ON public.blog_posts;
DROP POLICY IF EXISTS "Enable read access for anon, authenticated" ON public.blog_posts;
DROP POLICY IF EXISTS "Enable insert for anon, authenticated" ON public.blog_posts;
DROP POLICY IF EXISTS "Enable update for anon, authenticated" ON public.blog_posts;
DROP POLICY IF EXISTS "Enable delete for anon, authenticated" ON public.blog_posts;
DROP POLICY IF EXISTS "Public read access" ON public.blog_posts;
DROP POLICY IF EXISTS "Admin access" ON public.blog_posts;
DROP POLICY IF EXISTS "Owner access" ON public.blog_posts;
DROP POLICY IF EXISTS "Service role access" ON public.blog_posts;

-- Drop ALL policies on courses  
DROP POLICY IF EXISTS "All operations for courses" ON public.courses;
DROP POLICY IF EXISTS "Enable read access for anon, authenticated" ON public.courses;
DROP POLICY IF EXISTS "Enable insert for anon, authenticated" ON public.courses;
DROP POLICY IF EXISTS "Enable update for anon, authenticated" ON public.courses;
DROP POLICY IF EXISTS "Enable delete for anon, authenticated" ON public.courses;
DROP POLICY IF EXISTS "Public read access" ON public.courses;
DROP POLICY IF EXISTS "Admin access" ON public.courses;
DROP POLICY IF EXISTS "Owner access" ON public.courses;
DROP POLICY IF EXISTS "Service role access" ON public.courses;
DROP POLICY IF EXISTS "Public can view published courses" ON public.courses;
DROP POLICY IF EXISTS "Enable all access for admins" ON public.courses;

-- Drop ALL policies on course_modules
DROP POLICY IF EXISTS "All operations for course_modules" ON public.course_modules;
DROP POLICY IF EXISTS "Enable read access for anon, authenticated" ON public.course_modules;
DROP POLICY IF EXISTS "Enable insert for anon, authenticated" ON public.course_modules;
DROP POLICY IF EXISTS "Enable update for anon, authenticated" ON public.course_modules;
DROP POLICY IF EXISTS "Enable delete for anon, authenticated" ON public.course_modules;
DROP POLICY IF EXISTS "Public read access" ON public.course_modules;
DROP POLICY IF EXISTS "Admin access" ON public.course_modules;
DROP POLICY IF EXISTS "Owner access" ON public.course_modules;
DROP POLICY IF EXISTS "Service role access" ON public.course_modules;
DROP POLICY IF EXISTS "Public can view published modules" ON public.course_modules;
DROP POLICY IF EXISTS "Enable all access for admins modules" ON public.course_modules;

-- Drop ALL policies on course_topics
DROP POLICY IF EXISTS "All operations for course_topics" ON public.course_topics;
DROP POLICY IF EXISTS "Enable read access for anon, authenticated" ON public.course_topics;
DROP POLICY IF EXISTS "Enable insert for anon, authenticated" ON public.course_topics;
DROP POLICY IF EXISTS "Enable update for anon, authenticated" ON public.course_topics;
DROP POLICY IF EXISTS "Enable delete for anon, authenticated" ON public.course_topics;
DROP POLICY IF EXISTS "Public read access" ON public.course_topics;
DROP POLICY IF EXISTS "Admin access" ON public.course_topics;
DROP POLICY IF EXISTS "Owner access" ON public.course_topics;
DROP POLICY IF EXISTS "Service role access" ON public.course_topics;
DROP POLICY IF EXISTS "Public can view published topics" ON public.course_topics;
DROP POLICY IF EXISTS "Enable all access for admins topics" ON public.course_topics;

-- Drop ALL policies on testimonials
DROP POLICY IF EXISTS "All operations for testimonials" ON public.testimonials;
DROP POLICY IF EXISTS "Enable read access for anon, authenticated" ON public.testimonials;
DROP POLICY IF EXISTS "Enable insert for anon, authenticated" ON public.testimonials;
DROP POLICY IF EXISTS "Enable update for anon, authenticated" ON public.testimonials;
DROP POLICY IF EXISTS "Enable delete for anon, authenticated" ON public.testimonials;
DROP POLICY IF EXISTS "Public read access" ON public.testimonials;
DROP POLICY IF EXISTS "Admin access" ON public.testimonials;
DROP POLICY IF EXISTS "Owner access" ON public.testimonials;
DROP POLICY IF EXISTS "Service role access" ON public.testimonials;

-- Drop ALL policies on jobs
DROP POLICY IF EXISTS "All operations for jobs" ON public.jobs;
DROP POLICY IF EXISTS "Enable read access for anon, authenticated" ON public.jobs;
DROP POLICY IF EXISTS "Enable insert for anon, authenticated" ON public.jobs;
DROP POLICY IF EXISTS "Enable update for anon, authenticated" ON public.jobs;
DROP POLICY IF EXISTS "Enable delete for anon, authenticated" ON public.jobs;
DROP POLICY IF EXISTS "Public read access" ON public.jobs;
DROP POLICY IF EXISTS "Admin access" ON public.jobs;
DROP POLICY IF EXISTS "Owner access" ON public.jobs;
DROP POLICY IF EXISTS "Service role access" ON public.jobs;

-- Drop ALL policies on instagram_posts
DROP POLICY IF EXISTS "All operations for instagram_posts" ON public.instagram_posts;
DROP POLICY IF EXISTS "Enable read access for anon, authenticated" ON public.instagram_posts;
DROP POLICY IF EXISTS "Enable insert for anon, authenticated" ON public.instagram_posts;
DROP POLICY IF EXISTS "Enable update for anon, authenticated" ON public.instagram_posts;
DROP POLICY IF EXISTS "Enable delete for anon, authenticated" ON public.instagram_posts;
DROP POLICY IF EXISTS "Public read access" ON public.instagram_posts;
DROP POLICY IF EXISTS "Admin access" ON public.instagram_posts;
DROP POLICY IF EXISTS "Owner access" ON public.instagram_posts;
DROP POLICY IF EXISTS "Service role access" ON public.instagram_posts;

-- ================================================
-- STEP 2: DISABLE RLS ON ALL TABLES
-- ================================================
ALTER TABLE public.blog_posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_modules DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_topics DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.testimonials DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.instagram_posts DISABLE ROW LEVEL SECURITY;

-- ================================================
-- STEP 3: VERIFY RLS IS NOW DISABLED
-- ================================================
SELECT 
    c.relname as table_name,
    CASE 
        WHEN c.relrowsecurity THEN 'RLS ENABLED ❌ STILL BLOCKING'
        ELSE 'RLS DISABLED ✅ READY TO USE'
    END as rls_status,
    CASE 
        WHEN c.relrowsecurity THEN 'URGENT: RLS still blocking - check table structure'
        ELSE 'SUCCESS: All tables ready for course/blog creation'
    END as status_message
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' AND c.relname IN (
    'blog_posts', 'courses', 'course_modules', 'course_topics', 
    'testimonials', 'jobs', 'instagram_posts'
)
ORDER BY c.relname;

-- ================================================
-- STEP 4: TEST TABLE ACCESS
-- ================================================
-- This will test if service_role can actually insert data
DO $$
DECLARE
    test_course_id UUID;
    test_blog_id UUID;
BEGIN
    -- Test course insertion
    BEGIN
        INSERT INTO public.courses (
            title, description, subject, level, duration_weeks, created_by
        ) VALUES (
            'Test Course - ' || now()::text,
            'This is a test course to verify RLS is disabled',
            'Technology',
            'beginner',
            '4',
            'admin'
        ) RETURNING id INTO test_course_id;
        
        RAISE NOTICE '✅ SUCCESS: Course created with ID: %', test_course_id;
        
        -- Clean up test course
        DELETE FROM public.courses WHERE id = test_course_id;
        RAISE NOTICE '🧹 Test course cleaned up';
        
    EXCEPTION WHEN others THEN
        RAISE NOTICE '❌ COURSE TEST FAILED: %', SQLERRM;
    END;
    
    -- Test blog insertion  
    BEGIN
        INSERT INTO public.blog_posts (
            title, content, excerpt, author_name, category, tags, is_published, status
        ) VALUES (
            'Test Blog - ' || now()::text,
            'This is a test blog to verify RLS is disabled',
            'Testing RLS status',
            'Admin',
            'Technology',
            ARRAY['test', 'rls'],
            true,
            'published'
        ) RETURNING id INTO test_blog_id;
        
        RAISE NOTICE '✅ SUCCESS: Blog created with ID: %', test_blog_id;
        
        -- Clean up test blog
        DELETE FROM public.blog_posts WHERE id = test_blog_id;
        RAISE NOTICE '🧹 Test blog cleaned up';
        
    EXCEPTION WHEN others THEN
        RAISE NOTICE '❌ BLOG TEST FAILED: %', SQLERRM;
    END;
END $$;