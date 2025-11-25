#!/usr/bin/env python3
"""
AI Boss Admin - Quick Test Script
Tests the optimized system with mathematics course creation
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8000"
ADMIN_HEADERS = {
    'Content-Type': 'application/json',
    'User-Agent': 'AI-Boss-Admin-Test/1.0'
}

def log_message(message, level="INFO"):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {level}: {message}")

def test_health_check():
    """Test the health check endpoint"""
    log_message("Testing health check endpoint...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/health", timeout=10)
        
        if response.status_code == 200:
            health_data = response.json()
            log_message(f"✅ Health check successful: {health_data.get('status')}")
            return health_data
        else:
            log_message(f"❌ Health check failed: HTTP {response.status_code}", "ERROR")
            return None
            
    except Exception as e:
        log_message(f"❌ Health check error: {e}", "ERROR")
        return None

def test_system_status():
    """Test the system status endpoint"""
    log_message("Testing system status endpoint...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/system/status", timeout=10)
        
        if response.status_code == 200:
            status_data = response.json()
            log_message(f"✅ System status retrieved: {status_data.get('system', {}).get('status')}")
            return status_data
        else:
            log_message(f"❌ System status failed: HTTP {response.status_code}", "ERROR")
            return None
            
    except Exception as e:
        log_message(f"❌ System status error: {e}", "ERROR")
        return None

def test_get_courses():
    """Test getting existing courses"""
    log_message("Testing get courses endpoint...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/courses", headers=ADMIN_HEADERS, timeout=10)
        
        if response.status_code == 200:
            courses_data = response.json()
            courses = courses_data.get('data', [])
            log_message(f"✅ Retrieved {len(courses)} existing courses")
            return courses
        else:
            log_message(f"❌ Get courses failed: HTTP {response.status_code} - {response.text}", "ERROR")
            return []
            
    except Exception as e:
        log_message(f"❌ Get courses error: {e}", "ERROR")
        return []

def test_create_mathematics_course():
    """Test creating Mathematics Class 11 course"""
    log_message("Testing Mathematics Class 11 course creation...")
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/courses/mathematics-class11",
            headers=ADMIN_HEADERS,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                course = result.get('data', {})
                log_message(f"✅ Mathematics course created: {course.get('title')}")
                log_message(f"   Subject: {course.get('subject')}")
                log_message(f"   Grade: {course.get('grade_level')}")
                log_message(f"   Price: ₹{course.get('price')}")
                log_message(f"   Published: {course.get('is_published')}")
                return True
            else:
                log_message(f"❌ Course creation failed: {result.get('error')}", "ERROR")
                if result.get('action_required'):
                    log_message("⚠️  RLS Policy fix required - run RLS fix SQL in Supabase", "WARNING")
                return False
        else:
            log_message(f"❌ HTTP error: {response.status_code} - {response.text}", "ERROR")
            return False
            
    except Exception as e:
        log_message(f"❌ Course creation error: {e}", "ERROR")
        return False

def test_rls_policy_fix():
    """Test getting RLS policy fix"""
    log_message("Testing RLS policy fix endpoint...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/admin/rls-fix", timeout=10)
        
        if response.status_code == 200:
            fix_data = response.json()
            if fix_data.get('success'):
                log_message("✅ RLS policy fix instructions retrieved")
                log_message("📋 SQL Command ready for execution:")
                print()
                print("="*60)
                print(fix_data.get('sql', ''))
                print("="*60)
                print()
                return True
            else:
                log_message(f"❌ RLS fix failed: {fix_data.get('error')}", "ERROR")
                return False
        else:
            log_message(f"❌ RLS fix HTTP error: {response.status_code}", "ERROR")
            return False
            
    except Exception as e:
        log_message(f"❌ RLS fix error: {e}", "ERROR")
        return False

def test_web_interface():
    """Test web interface accessibility"""
    log_message("Testing web interface...")
    
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        
        if response.status_code == 200:
            if "AI Boss Admin" in response.text:
                log_message("✅ Web interface accessible and loaded correctly")
                return True
            else:
                log_message("❌ Web interface loaded but content incorrect", "ERROR")
                return False
        else:
            log_message(f"❌ Web interface failed: HTTP {response.status_code}", "ERROR")
            return False
            
    except Exception as e:
        log_message(f"❌ Web interface error: {e}", "ERROR")
        return False

def test_instagram_post():
    """Test Instagram post creation"""
    log_message("Testing Instagram post creation...")
    
    try:
        post_data = {
            "url": "https://www.instagram.com/p/test123/",
            "caption": "Test Instagram post from AI Boss Admin",
            "tags": ["test", "ai-admin", "celorisdesigns"]
        }
        
        response = requests.post(
            f"{BASE_URL}/api/instagram/posts",
            json=post_data,
            headers=ADMIN_HEADERS,
            timeout=15
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                log_message("✅ Instagram post created successfully")
                return True
            else:
                log_message(f"❌ Instagram post failed: {result.get('error')}", "ERROR")
                return False
        else:
            log_message(f"❌ Instagram post HTTP error: {response.status_code}", "ERROR")
            return False
            
    except Exception as e:
        log_message(f"❌ Instagram post error: {e}", "ERROR")
        return False

def run_comprehensive_test():
    """Run comprehensive test suite"""
    print()
    print("="*60)
    print("🧪 AI BOSS ADMIN - COMPREHENSIVE TEST SUITE")
    print("="*60)
    print()
    
    # Wait for service to be ready
    log_message("Waiting for service to be ready...")
    time.sleep(3)
    
    # Test results
    results = {
        'health_check': test_health_check(),
        'system_status': test_system_status(),
        'web_interface': test_web_interface(),
        'get_courses': test_get_courses(),
        'rls_fix': test_rls_policy_fix(),
        'instagram_post': test_instagram_post(),
        'mathematics_course': test_create_mathematics_course()
    }
    
    # Summary
    print()
    print("="*60)
    print("📊 TEST RESULTS SUMMARY")
    print("="*60)
    
    passed = 0
    failed = 0
    
    for test_name, result in results.items():
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{test_name.replace('_', ' ').title():<25} {status}")
        
        if result:
            passed += 1
        else:
            failed += 1
    
    print()
    print(f"Total Tests: {len(results)}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Success Rate: {(passed/len(results)*100):.1f}%")
    
    if failed == 0:
        print()
        log_message("🎉 ALL TESTS PASSED! AI Boss Admin is fully operational!", "SUCCESS")
    else:
        print()
        log_message("⚠️  Some tests failed. Check the logs above for details.", "WARNING")
    
    return results

if __name__ == "__main__":
    # Check if service is running
    try:
        health_response = requests.get(f"{BASE_URL}/api/health", timeout=5)
        if health_response.status_code != 200:
            print("❌ Service is not running or not accessible")
            print("Please start the service first:")
            print("  sudo systemctl start ai-boss-admin")
            exit(1)
    except Exception as e:
        print("❌ Cannot connect to AI Boss Admin service")
        print(f"Error: {e}")
        print()
        print("Please start the service first:")
        print("  sudo systemctl start ai-boss-admin")
        exit(1)
    
    # Run tests
    run_comprehensive_test()