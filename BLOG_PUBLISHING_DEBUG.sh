#!/bin/bash

echo "🔍 BLOG PUBLISHING DEBUG SCRIPT"
echo "=============================="

cd /opt/ai-boss-admin
source venv/bin/activate

echo "📋 Step 1: Checking blog table RLS status..."
python3 << 'EOF'
import os
from supabase import create_client

try:
    supabase = create_client(
        os.getenv('SUPABASE_URL'), 
        os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    )
    
    print("🔍 Checking blog tables and their structure...")
    
    # Check what blog tables exist
    blog_tables = ['blogs', 'blog_posts', 'blog_comments', 'blog_automation']
    
    for table in blog_tables:
        try:
            # Test basic query
            result = supabase.table(table).select('count').execute()
            print(f"✅ {table}: Accessible ({len(result.data)} records)")
            
            # Get sample structure if available
            if result.data:
                sample = supabase.table(table).select('*').limit(1).execute()
                if sample.data:
                    print(f"   📊 Fields: {list(sample.data[0].keys())}")
                    
        except Exception as e:
            print(f"❌ {table}: Error - {str(e)}")
            if 'Row Level Security' in str(e):
                print(f"   🔒 RLS blocking {table}")

except Exception as e:
    print(f"❌ Database connection failed: {e}")
EOF

echo ""
echo "📋 Step 2: Testing blog creation..."

python3 << 'EOF'
import os
from supabase import create_client

try:
    supabase = create_client(
        os.getenv('SUPABASE_URL'), 
        os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    )
    
    print("🧪 Testing blog creation...")
    
    # Try to create a test blog
    test_blog = {
        'title': 'Debug Blog Post',
        'content': 'This is a test blog post for debugging purposes.',
        'excerpt': 'Test blog excerpt',
        'status': 'published',  # or 'draft'
        'author': 'AI Boss Admin',
        'published_at': '2025-11-24T22:30:00Z',
        'created_by': '550e8400-e29b-41d4-a716-446655440000'
    }
    
    result = supabase.table('blogs').insert(test_blog).execute()
    
    if result.data:
        blog_id = result.data[0].get('id')
        print(f"✅ Blog created successfully! ID: {blog_id}")
        
        # Try to read it back
        read_back = supabase.table('blogs').select('*').eq('id', blog_id).execute()
        if read_back.data:
            print("✅ Blog can be read back")
        
        # Clean up
        supabase.table('blogs').delete().eq('id', blog_id).execute()
        print("🧹 Test blog cleaned up")
        
    else:
        print("⚠️ Blog insert succeeded but returned no data")
        
except Exception as e:
    print(f"❌ Blog creation failed: {str(e)}")
    
    error_str = str(e).lower()
    if 'row level security' in error_str:
        print("🔒 RLS is blocking blog operations")
    elif 'does not exist' in error_str:
        print("🔧 Blog table/column doesn't exist")
    elif 'permission denied' in error_str:
        print("🔐 Permission denied for service role")
    else:
        print("❓ Different error")
EOF

echo ""
echo "📋 Step 3: Checking what blogs actually exist..."

python3 << 'EOF'
import os
from supabase import create_client

try:
    supabase = create_client(
        os.getenv('SUPABASE_URL'), 
        os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    )
    
    print("📊 Fetching all existing blogs...")
    
    blogs = supabase.table('blogs').select('*').order('created_at', desc=True).execute()
    
    if blogs.data:
        print(f"✅ Found {len(blogs.data)} blogs:")
        for i, blog in enumerate(blogs.data[:5]):  # Show first 5
            print(f"   {i+1}. {blog.get('title', 'No title')} - Status: {blog.get('status', 'Unknown')}")
            print(f"      Created: {blog.get('created_at', 'Unknown')}")
    else:
        print("📭 No blogs found in database")
        
except Exception as e:
    print(f"❌ Cannot fetch blogs: {e}")

EOF

echo ""
echo "🔧 Step 4: Service status..."
sudo systemctl status ai-boss-admin --no-pager -l