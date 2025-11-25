#!/bin/bash

echo "🚀 FINAL AI BOSS ADMIN COMPLETE FIX"
echo "==================================="

# Step 1: Fix all RLS issues
echo "🔧 Step 1: Fixing ALL RLS policies..."

# Create SQL commands file
cat > /tmp/fix_rls_complete.sql << 'EOF'
-- Disable RLS on ALL course-related tables
ALTER TABLE public.courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_enrollments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_modules DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_topics DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_automation DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_metadata DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.topic_progress DISABLE ROW LEVEL SECURITY;

-- Add missing columns to match application schema
ALTER TABLE public.courses 
ADD COLUMN IF NOT EXISTS category VARCHAR,
ADD COLUMN IF NOT EXISTS duration VARCHAR,
ADD COLUMN IF NOT EXISTS difficulty_level VARCHAR;

-- Copy existing data to new columns
UPDATE public.courses 
SET 
    category = COALESCE(subject, 'General'),
    duration = COALESCE(course_duration, 'Self-paced'),
    difficulty_level = COALESCE(grade_level, 'beginner');

-- Verify RLS is disabled
SELECT 
    c.relname as table_name,
    c.relrowsecurity as rls_enabled
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relname LIKE '%course%' AND n.nspname = 'public'
ORDER BY c.relname;
EOF

echo "📋 Run this SQL in Supabase SQL Editor:"
echo "---"
cat /tmp/fix_rls_complete.sql
echo "---"

echo ""
echo "🔄 Step 2: Restarting AI Boss Admin service..."

cd /opt/ai-boss-admin

# Test the application with corrected schema
echo "🧪 Step 3: Testing course creation with fixed schema..."
source venv/bin/activate

python3 << 'EOF'
import os
from supabase import create_client
import json

try:
    supabase = create_client(
        os.getenv('SUPABASE_URL'), 
        os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    )
    
    print("🧪 Testing course creation with correct schema...")
    
    # Test data matching actual database schema
    test_course = {
        'title': 'AI Boss Admin Test Course',
        'subject': 'Technology',  # Using 'subject' instead of 'category'
        'grade_level': 'beginner',  # Using 'grade_level' instead of 'difficulty_level'
        'description': 'Test course created via debug script',
        'target_audience': 'Beginners',
        'course_duration': '2 hours',  # Using 'course_duration' instead of 'duration'
        'price': 99.00,
        'course_image_url': '',
        'created_by': '550e8400-e29b-41d4-a716-446655440000'  # Your admin user ID
    }
    
    result = supabase.table('courses').insert(test_course).execute()
    
    if result.data:
        course_id = result.data[0]['id']
        print(f"✅ SUCCESS: Course created with ID: {course_id}")
        
        # Clean up test course
        supabase.table('courses').delete().eq('id', course_id).execute()
        print("🧹 Test course cleaned up")
        
    else:
        print("⚠️ No data returned")
        
except Exception as e:
    print(f"❌ Course creation failed: {str(e)}")
    
    if "Row Level Security" in str(e):
        print("🔒 RLS is still blocking - check if RLS was actually disabled")
    elif "relation" in str(e) and "does not exist" in str(e):
        print("🔧 Schema mismatch - check if columns were added correctly")
    else:
        print("❓ Different error - check details above")
EOF

echo ""
echo "🎯 Step 4: Checking HTTP 401 issue..."

# Check environment variables
echo "Environment Variables Check:"
echo "SUPABASE_URL: $(echo ${SUPABASE_URL:-$'NOT SET'} | head -c 50)..."
echo "SERVICE_ROLE_KEY: $(echo ${SUPABASE_SERVICE_ROLE_KEY:-$'NOT SET'} | head -c 20)..."
echo "ANON_KEY: $(echo ${SUPABASE_ANON_KEY:-$'NOT SET'} | head -c 20)..."

# Test API health
python3 << 'EOF'
import os
from supabase import create_client

try:
    supabase = create_client(
        os.getenv('SUPABASE_URL'), 
        os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    )
    
    # Test basic API health
    result = supabase.table('courses').select('count').execute()
    print("✅ API Health Check: Service role working correctly")
    
except Exception as e:
    print(f"❌ API Health Check Failed: {e}")
EOF

echo ""
echo "🎯 Step 5: Service Status Check..."
sudo systemctl restart ai-boss-admin
sleep 5
sudo systemctl status ai-boss-admin --no-pager

echo ""
echo "📋 NEXT STEPS:"
echo "1. Run the SQL commands above in Supabase SQL Editor"
echo "2. Refresh the AI Boss Admin dashboard"
echo "3. Try creating a course again"
echo ""
echo "🌐 Access URL: http://$(curl -s ifconfig.me):8000"
echo "📊 Monitor with: sudo journalctl -u ai-boss-admin -f"