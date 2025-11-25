#!/bin/bash

echo "🔍 COMPREHENSIVE RLS DEBUG SCRIPT"
echo "=================================="

# Step 1: Check database connection and RLS status
echo "🔗 Step 1: Testing database connection..."
cd /opt/ai-boss-admin
source venv/bin/activate

python3 << 'EOF'
import os
from supabase import create_client

try:
    # Test connection
    supabase = create_client(
        os.getenv('SUPABASE_URL'), 
        os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    )
    print("✅ Database connection successful")
    
    # Check what role we're using
    print(f"📊 Using service role key: {os.getenv('SUPABASE_SERVICE_ROLE_KEY')[:50]}...")
    
except Exception as e:
    print(f"❌ Database connection failed: {e}")
    exit(1)

# Step 2: Check RLS status and policies
try:
    # Check courses table RLS status
    result = supabase.rpc('check_rls_status', {'table_name': 'courses'}).execute()
    print(f"📋 RLS Status Check: {result.data}")
except Exception as e:
    print(f"⚠️ RPC check failed: {e}")
    print("Will use direct SQL queries...")
EOF

# Step 3: Get exact error from logs
echo ""
echo "📋 Step 2: Checking application logs..."
sudo journalctl -u ai-boss-admin -n 50 --no-pager | grep -i -E "(error|course|insert|rls|security)" | tail -20

echo ""
echo "🔍 Step 3: Test manual course creation..."
source venv/bin/activate

python3 << 'EOF'
import os
from supabase import create_client

try:
    supabase = create_client(
        os.getenv('SUPABASE_URL'), 
        os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    )
    
    print("🧪 Attempting manual course creation...")
    
    # Try to insert a test course
    test_data = {
        'title': 'Debug Test Course',
        'description': 'Testing course creation',
        'category': 'Debug',
        'price': 99,
        'duration': '1 hour',
        'difficulty_level': 'beginner'
    }
    
    result = supabase.table('courses').insert(test_data).execute()
    
    if result.data:
        print("✅ Manual course creation SUCCESS!")
        print(f"📊 Course ID: {result.data[0].get('id', 'N/A')}")
        
        # Clean up test course
        if 'id' in result.data[0]:
            supabase.table('courses').delete().eq('id', result.data[0]['id']).execute()
            print("🧹 Test course cleaned up")
    else:
        print("⚠️ No data returned from insert")
        
except Exception as e:
    print(f"❌ Manual course creation failed: {str(e)}")
    
    # Try to get more specific error info
    if "Row Level Security" in str(e):
        print("🔒 CONFIRMED: RLS is still blocking the operation")
    elif "permission denied" in str(e):
        print("🔐 CONFIRMED: Permission denied issue")
    else:
        print("❓ Different error - check the full error above")

EOF

echo ""
echo "🔍 Step 4: Check related tables and policies..."

# Create a SQL file to check everything
cat > /tmp/rls_debug.sql << 'EOF'
-- Check all courses-related tables
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename LIKE '%course%' AND schemaname = 'public';

-- Check policies on courses
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'courses';

-- Check table permissions for service_role
SELECT 
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'courses' AND grantee = 'service_role';
EOF

echo "Run this SQL in Supabase to check table status:"
echo "---"
cat /tmp/rls_debug.sql
echo "---"

echo ""
echo "🎯 Summary of what to check:"
echo "1. Are there other related tables (lessons, enrollments, etc.) with RLS enabled?"
echo "2. Is the service_role user properly granted permissions?"
echo "3. Are there any triggers or constraints blocking the insert?"
echo ""
echo "📝 Next steps based on results above."