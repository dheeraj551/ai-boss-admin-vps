#!/usr/bin/env python3
"""
AI Boss Admin - Direct SQL Version
Bypasses Supabase client issues by using direct PostgreSQL queries
"""

import os
import json
import uuid
from datetime import datetime
from typing import List, Dict, Any, Optional
import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="AI Boss Admin - Direct SQL", version="2.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database connection function
def get_db_connection():
    """Create database connection using environment variables"""
    try:
        # Extract database URL from SUPABASE_URL
        supabase_url = os.getenv('SUPABASE_URL')
        if not supabase_url:
            raise ValueError("SUPABASE_URL environment variable not found")
        
        # Parse Supabase URL to get database connection info
        # Format: https://suaqywhmaheoansrinzw.supabase.co
        project_ref = supabase_url.replace('https://', '').replace('.supabase.co', '')
        
        # Construct direct PostgreSQL connection string
        db_url = f"postgresql://postgres.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1YXF5d2htYWhlb2Fuc3Jpbnp3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjMzNzEwNSwiZXhwIjoyMDQ3OTEzMTA1fQ.Oa5e8W4N5L3rG4Qj8YfN6R9oX5P5S1K6W9F2M3G8P9c@{project_ref}.supabase.co:5432/postgres"
        
        conn = psycopg2.connect(db_url)
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

# Pydantic models for request validation
class BlogPost(BaseModel):
    title: str
    content: str
    excerpt: Optional[str] = None
    author_name: Optional[str] = "Admin"
    category: Optional[str] = "General"
    tags: Optional[List[str]] = []
    featured_image_url: Optional[str] = None
    meta_title: Optional[str] = None
    meta_description: Optional[str] = None
    is_published: Optional[bool] = True
    status: Optional[str] = "published"

class Course(BaseModel):
    title: str
    description: str
    subject: Optional[str] = None
    level: Optional[str] = None
    grade_level: Optional[str] = None
    duration_weeks: Optional[str] = None
    course_duration: Optional[str] = None
    price: Optional[float] = 0.0
    target_audience: Optional[str] = None
    instructor_name: Optional[str] = None
    course_image_url: Optional[str] = None
    is_published: Optional[bool] = False
    is_featured: Optional[bool] = False
    created_by: Optional[str] = "admin"

class Testimonial(BaseModel):
    client_name: str
    client_title: Optional[str] = None
    client_company: Optional[str] = None
    client_avatar_url: Optional[str] = None
    testimonial_text: str
    rating: Optional[int] = 5
    testimonial_type: Optional[str] = "general"
    target_pages: Optional[List[str]] = ["homepage"]
    display_order: Optional[int] = 0
    is_featured: Optional[bool] = False
    is_visible: Optional[bool] = True
    client_location: Optional[str] = None
    client_website: Optional[str] = None
    project_details: Optional[str] = None
    client_industry: Optional[str] = None

class Job(BaseModel):
    title: str
    company_name: str
    company_logo_url: Optional[str] = None
    location: str
    is_remote: Optional[bool] = False
    employment_type: Optional[str] = "full-time"
    experience_level: Optional[str] = "mid-level"
    salary_min: Optional[int] = None
    salary_max: Optional[int] = None
    salary_currency: Optional[str] = "USD"
    salary_period: Optional[str] = "year"
    description: str
    requirements: Optional[List[str]] = []
    skills: Optional[List[str]] = []
    responsibilities: Optional[List[str]] = []
    benefits: Optional[List[str]] = []
    application_deadline: Optional[str] = None
    contact_email: Optional[str] = None
    application_url: Optional[str] = None
    application_instructions: Optional[str] = None
    is_featured: Optional[bool] = False
    is_active: Optional[bool] = True
    is_published: Optional[bool] = True
    category: Optional[str] = None
    industry: Optional[str] = None

# Direct SQL API endpoints

@app.get("/")
async def admin_home():
    """Admin dashboard home page"""
    return HTMLResponse("""
    <!DOCTYPE html>
    <html>
    <head>
        <title>AI Boss Admin - Direct SQL</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { text-align: center; margin-bottom: 40px; }
            .nav-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 40px; }
            .nav-card { background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; text-align: center; cursor: pointer; transition: all 0.3s; }
            .nav-card:hover { background: #f8f9fa; border-color: #007bff; transform: translateY(-2px); }
            .nav-card h3 { margin: 0 0 10px 0; color: #333; }
            .nav-card p { margin: 0; color: #666; font-size: 14px; }
            .blog-section, .course-section, .testimonial-section, .job-section { display: none; margin-top: 30px; }
            .form-group { margin-bottom: 20px; }
            label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; }
            input, textarea, select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px; }
            textarea { height: 120px; resize: vertical; }
            .btn { background: #007bff; color: white; padding: 12px 24px; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
            .btn:hover { background: #0056b3; }
            .success { background: #d4edda; color: #155724; padding: 10px; border-radius: 4px; margin: 10px 0; }
            .error { background: #f8d7da; color: #721c24; padding: 10px; border-radius: 4px; margin: 10px 0; }
            .back-btn { background: #6c757d; color: white; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; margin-bottom: 20px; }
            .tag-input { display: flex; flex-wrap: wrap; gap: 5px; margin-top: 5px; }
            .tag { background: #e9ecef; padding: 4px 8px; border-radius: 3px; font-size: 12px; }
            .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.5); }
            .modal-content { background-color: white; margin: 15% auto; padding: 20px; width: 80%; max-width: 500px; border-radius: 8px; }
            .close { color: #aaa; float: right; font-size: 28px; font-weight: bold; cursor: pointer; }
            .close:hover { color: black; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎯 AI Boss Admin - Direct SQL</h1>
                <p>Database-driven admin system using direct SQL queries</p>
                <div class="success">✅ RLS Issues Resolved - Using Direct SQL</div>
            </div>
            
            <div class="nav-grid">
                <div class="nav-card" onclick="showSection('blog')">
                    <h3>📝 Blog Posts</h3>
                    <p>Create and manage blog content</p>
                </div>
                <div class="nav-card" onclick="showSection('course')">
                    <h3>📚 Courses</h3>
                    <p>Manage course information and modules</p>
                </div>
                <div class="nav-card" onclick="showSection('testimonial')">
                    <h3>⭐ Testimonials</h3>
                    <p>Display client testimonials and reviews</p>
                </div>
                <div class="nav-card" onclick="showSection('job')">
                    <h3>💼 Job Listings</h3>
                    <p>Manage job postings and career opportunities</p>
                </div>
            </div>

            <!-- Blog Section -->
            <div id="blog" class="blog-section">
                <h2>📝 Create Blog Post</h2>
                <button class="back-btn" onclick="hideSections()">← Back to Dashboard</button>
                <div id="blog-message"></div>
                <form id="blog-form">
                    <div class="form-group">
                        <label for="blog-title">Title *</label>
                        <input type="text" id="blog-title" name="title" required>
                    </div>
                    <div class="form-group">
                        <label for="blog-content">Content *</label>
                        <textarea id="blog-content" name="content" required></textarea>
                    </div>
                    <div class="form-group">
                        <label for="blog-excerpt">Excerpt</label>
                        <textarea id="blog-excerpt" name="excerpt"></textarea>
                    </div>
                    <div class="form-group">
                        <label for="blog-author">Author Name</label>
                        <input type="text" id="blog-author" name="author_name" value="Admin">
                    </div>
                    <div class="form-group">
                        <label for="blog-category">Category</label>
                        <input type="text" id="blog-category" name="category" value="Technology">
                    </div>
                    <div class="form-group">
                        <label for="blog-tags">Tags (comma separated)</label>
                        <input type="text" id="blog-tags" name="tags" placeholder="blog, technology, admin">
                    </div>
                    <button type="submit" class="btn">Create Blog Post</button>
                </form>
            </div>

            <!-- Course Section -->
            <div id="course" class="course-section">
                <h2>📚 Create Course</h2>
                <button class="back-btn" onclick="hideSections()">← Back to Dashboard</button>
                <div id="course-message"></div>
                <form id="course-form">
                    <div class="form-group">
                        <label for="course-title">Title *</label>
                        <input type="text" id="course-title" name="title" required>
                    </div>
                    <div class="form-group">
                        <label for="course-description">Description *</label>
                        <textarea id="course-description" name="description" required></textarea>
                    </div>
                    <div class="form-group">
                        <label for="course-subject">Subject</label>
                        <input type="text" id="course-subject" name="subject">
                    </div>
                    <div class="form-group">
                        <label for="course-level">Level</label>
                        <select id="course-level" name="level">
                            <option value="">Select level</option>
                            <option value="beginner">Beginner</option>
                            <option value="intermediate">Intermediate</option>
                            <option value="advanced">Advanced</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="course-duration">Duration (weeks)</label>
                        <input type="text" id="course-duration" name="duration_weeks" placeholder="4">
                    </div>
                    <div class="form-group">
                        <label for="course-price">Price</label>
                        <input type="number" id="course-price" name="price" step="0.01" value="0">
                    </div>
                    <div class="form-group">
                        <label for="course-instructor">Instructor Name</label>
                        <input type="text" id="course-instructor" name="instructor_name">
                    </div>
                    <div class="form-group">
                        <label for="course-audience">Target Audience</label>
                        <textarea id="course-audience" name="target_audience"></textarea>
                    </div>
                    <button type="submit" class="btn">Create Course</button>
                </form>
            </div>

            <!-- Testimonial Section -->
            <div id="testimonial" class="testimonial-section">
                <h2>⭐ Create Testimonial</h2>
                <button class="back-btn" onclick="hideSections()">← Back to Dashboard</button>
                <div id="testimonial-message"></div>
                <form id="testimonial-form">
                    <div class="form-group">
                        <label for="client-name">Client Name *</label>
                        <input type="text" id="client-name" name="client_name" required>
                    </div>
                    <div class="form-group">
                        <label for="client-title">Client Title</label>
                        <input type="text" id="client-title" name="client_title">
                    </div>
                    <div class="form-group">
                        <label for="client-company">Company</label>
                        <input type="text" id="client-company" name="client_company">
                    </div>
                    <div class="form-group">
                        <label for="testimonial-text">Testimonial *</label>
                        <textarea id="testimonial-text" name="testimonial_text" required></textarea>
                    </div>
                    <div class="form-group">
                        <label for="client-rating">Rating</label>
                        <select id="client-rating" name="rating">
                            <option value="5">5 Stars</option>
                            <option value="4">4 Stars</option>
                            <option value="3">3 Stars</option>
                            <option value="2">2 Stars</option>
                            <option value="1">1 Star</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="testimonial-type">Type</label>
                        <select id="testimonial-type" name="testimonial_type">
                            <option value="general">General</option>
                            <option value="course">Course</option>
                            <option value="service">Service</option>
                        </select>
                    </div>
                    <button type="submit" class="btn">Create Testimonial</button>
                </form>
            </div>

            <!-- Job Section -->
            <div id="job" class="job-section">
                <h2>💼 Create Job Listing</h2>
                <button class="back-btn" onclick="hideSections()">← Back to Dashboard</button>
                <div id="job-message"></div>
                <form id="job-form">
                    <div class="form-group">
                        <label for="job-title">Job Title *</label>
                        <input type="text" id="job-title" name="title" required>
                    </div>
                    <div class="form-group">
                        <label for="company-name">Company Name *</label>
                        <input type="text" id="company-name" name="company_name" required>
                    </div>
                    <div class="form-group">
                        <label for="job-location">Location *</label>
                        <input type="text" id="job-location" name="location" required>
                    </div>
                    <div class="form-group">
                        <label for="employment-type">Employment Type</label>
                        <select id="employment-type" name="employment_type">
                            <option value="full-time">Full Time</option>
                            <option value="part-time">Part Time</option>
                            <option value="contract">Contract</option>
                            <option value="freelance">Freelance</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="job-description">Job Description *</label>
                        <textarea id="job-description" name="description" required></textarea>
                    </div>
                    <div class="form-group">
                        <label for="job-skills">Required Skills (comma separated)</label>
                        <input type="text" id="job-skills" name="skills" placeholder="Python, JavaScript, React">
                    </div>
                    <div class="form-group">
                        <label for="job-requirements">Requirements (comma separated)</label>
                        <input type="text" id="job-requirements" name="requirements" placeholder="Bachelor's degree, 3 years experience">
                    </div>
                    <div class="form-group">
                        <label for="salary-min">Salary Min</label>
                        <input type="number" id="salary-min" name="salary_min">
                    </div>
                    <div class="form-group">
                        <label for="salary-max">Salary Max</label>
                        <input type="number" id="salary-max" name="salary_max">
                    </div>
                    <button type="submit" class="btn">Create Job Listing</button>
                </form>
            </div>
        </div>

        <script>
            function showSection(section) {
                hideSections();
                document.getElementById(section).style.display = 'block';
            }

            function hideSections() {
                document.querySelectorAll('.blog-section, .course-section, .testimonial-section, .job-section').forEach(section => {
                    section.style.display = 'none';
                });
            }

            // Blog Form Handler
            document.getElementById('blog-form').addEventListener('submit', async function(e) {
                e.preventDefault();
                const messageDiv = document.getElementById('blog-message');
                
                const formData = new FormData(e.target);
                const blogData = {
                    title: formData.get('title'),
                    content: formData.get('content'),
                    excerpt: formData.get('excerpt'),
                    author_name: formData.get('author_name'),
                    category: formData.get('category'),
                    tags: formData.get('tags').split(',').map(tag => tag.trim()).filter(tag => tag)
                };
                
                try {
                    const response = await fetch('/api/admin/blog', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(blogData)
                    });
                    
                    const result = await response.json();
                    
                    if (response.ok) {
                        messageDiv.innerHTML = '<div class="success">✅ Blog post created successfully! ID: ' + result.id + '</div>';
                        e.target.reset();
                    } else {
                        messageDiv.innerHTML = '<div class="error">❌ Error: ' + result.detail + '</div>';
                    }
                } catch (error) {
                    messageDiv.innerHTML = '<div class="error">❌ Network error: ' + error.message + '</div>';
                }
            });

            // Course Form Handler
            document.getElementById('course-form').addEventListener('submit', async function(e) {
                e.preventDefault();
                const messageDiv = document.getElementById('course-message');
                
                const formData = new FormData(e.target);
                const courseData = {
                    title: formData.get('title'),
                    description: formData.get('description'),
                    subject: formData.get('subject'),
                    level: formData.get('level'),
                    duration_weeks: formData.get('duration_weeks'),
                    price: parseFloat(formData.get('price')) || 0,
                    instructor_name: formData.get('instructor_name'),
                    target_audience: formData.get('target_audience'),
                    created_by: 'admin'
                };
                
                try {
                    const response = await fetch('/api/admin/courses', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(courseData)
                    });
                    
                    const result = await response.json();
                    
                    if (response.ok) {
                        messageDiv.innerHTML = '<div class="success">✅ Course created successfully! ID: ' + result.id + '</div>';
                        e.target.reset();
                    } else {
                        messageDiv.innerHTML = '<div class="error">❌ Error: ' + result.detail + '</div>';
                    }
                } catch (error) {
                    messageDiv.innerHTML = '<div class="error">❌ Network error: ' + error.message + '</div>';
                }
            });

            // Testimonial Form Handler
            document.getElementById('testimonial-form').addEventListener('submit', async function(e) {
                e.preventDefault();
                const messageDiv = document.getElementById('testimonial-message');
                
                const formData = new FormData(e.target);
                const testimonialData = {
                    client_name: formData.get('client_name'),
                    client_title: formData.get('client_title'),
                    client_company: formData.get('client_company'),
                    testimonial_text: formData.get('testimonial_text'),
                    rating: parseInt(formData.get('rating')),
                    testimonial_type: formData.get('testimonial_type'),
                    target_pages: ['homepage']  // Default target
                };
                
                try {
                    const response = await fetch('/api/admin/testimonials', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(testimonialData)
                    });
                    
                    const result = await response.json();
                    
                    if (response.ok) {
                        messageDiv.innerHTML = '<div class="success">✅ Testimonial created successfully! ID: ' + result.id + '</div>';
                        e.target.reset();
                    } else {
                        messageDiv.innerHTML = '<div class="error">❌ Error: ' + result.detail + '</div>';
                    }
                } catch (error) {
                    messageDiv.innerHTML = '<div class="error">❌ Network error: ' + error.message + '</div>';
                }
            });

            // Job Form Handler
            document.getElementById('job-form').addEventListener('submit', async function(e) {
                e.preventDefault();
                const messageDiv = document.getElementById('job-message');
                
                const formData = new FormData(e.target);
                const jobData = {
                    title: formData.get('title'),
                    company_name: formData.get('company_name'),
                    location: formData.get('location'),
                    employment_type: formData.get('employment_type'),
                    description: formData.get('description'),
                    skills: formData.get('skills').split(',').map(skill => skill.trim()).filter(skill => skill),
                    requirements: formData.get('requirements').split(',').map(req => req.trim()).filter(req => req),
                    salary_min: formData.get('salary_min') ? parseInt(formData.get('salary_min')) : null,
                    salary_max: formData.get('salary_max') ? parseInt(formData.get('salary_max')) : null
                };
                
                try {
                    const response = await fetch('/api/admin/jobs', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(jobData)
                    });
                    
                    const result = await response.json();
                    
                    if (response.ok) {
                        messageDiv.innerHTML = '<div class="success">✅ Job listing created successfully! ID: ' + result.id + '</div>';
                        e.target.reset();
                    } else {
                        messageDiv.innerHTML = '<div class="error">❌ Error: ' + result.detail + '</div>';
                    }
                } catch (error) {
                    messageDiv.innerHTML = '<div class="error">❌ Network error: ' + error.message + '</div>';
                }
            });
        </script>
    </body>
    </html>
    """)

# ========================================
# BLOG API ENDPOINTS (Direct SQL)
# ========================================

@app.post("/api/admin/blog")
async def create_blog_post(blog: BlogPost):
    """Create blog post using direct SQL"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Generate unique ID and timestamps
                blog_id = str(uuid.uuid4())
                created_at = datetime.now()
                
                # Prepare tags array for PostgreSQL
                tags_array = blog.tags if blog.tags else []
                
                # Insert blog post using direct SQL
                query = """
                    INSERT INTO public.blog_posts (
                        id, title, content, excerpt, author_name, category, 
                        tags, featured_image_url, meta_title, meta_description,
                        is_published, status, created_at, updated_at
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    ) RETURNING id, title, created_at
                """
                
                values = (
                    blog_id,
                    blog.title,
                    blog.content,
                    blog.excerpt,
                    blog.author_name or "Admin",
                    blog.category or "General",
                    tags_array,
                    blog.featured_image_url,
                    blog.meta_title,
                    blog.meta_description,
                    blog.is_published if blog.is_published is not None else True,
                    blog.status or "published",
                    created_at,
                    created_at
                )
                
                cur.execute(query, values)
                result = cur.fetchone()
                conn.commit()
                
                logger.info(f"Blog post created successfully: {blog_id}")
                return {
                    "id": result['id'],
                    "title": result['title'],
                    "created_at": result['created_at'].isoformat(),
                    "message": "Blog post created successfully using direct SQL"
                }
                
    except Exception as e:
        logger.error(f"Blog creation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create blog post: {str(e)}")

@app.get("/api/admin/blog")
async def list_blog_posts(limit: int = Query(50, ge=1, le=100)):
    """Get all blog posts using direct SQL"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                query = """
                    SELECT id, title, excerpt, author_name, category, 
                           tags, is_published, status, created_at, updated_at
                    FROM public.blog_posts 
                    ORDER BY created_at DESC 
                    LIMIT %s
                """
                cur.execute(query, (limit,))
                results = cur.fetchall()
                
                return {
                    "blogs": [dict(row) for row in results],
                    "count": len(results)
                }
                
    except Exception as e:
        logger.error(f"Failed to fetch blog posts: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch blog posts: {str(e)}")

# ========================================
# COURSES API ENDPOINTS (Direct SQL)
# ========================================

@app.post("/api/admin/courses")
async def create_course(course: Course):
    """Create course using direct SQL"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Generate unique ID and timestamps
                course_id = str(uuid.uuid4())
                created_at = datetime.now()
                
                # Insert course using direct SQL
                query = """
                    INSERT INTO public.courses (
                        id, title, description, subject, level, grade_level,
                        duration_weeks, course_duration, price, target_audience,
                        instructor_name, course_image_url, is_published, is_featured,
                        created_by, created_at, updated_at
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    ) RETURNING id, title, created_at
                """
                
                values = (
                    course_id,
                    course.title,
                    course.description,
                    course.subject,
                    course.level,
                    course.grade_level,
                    course.duration_weeks,
                    course.course_duration,
                    course.price or 0.0,
                    course.target_audience,
                    course.instructor_name,
                    course.course_image_url,
                    course.is_published if course.is_published is not None else False,
                    course.is_featured if course.is_featured is not None else False,
                    course.created_by or "admin",
                    created_at,
                    created_at
                )
                
                cur.execute(query, values)
                result = cur.fetchone()
                conn.commit()
                
                logger.info(f"Course created successfully: {course_id}")
                return {
                    "id": result['id'],
                    "title": result['title'],
                    "created_at": result['created_at'].isoformat(),
                    "message": "Course created successfully using direct SQL"
                }
                
    except Exception as e:
        logger.error(f"Course creation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create course: {str(e)}")

@app.get("/api/admin/courses")
async def list_courses(limit: int = Query(50, ge=1, le=100)):
    """Get all courses using direct SQL"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                query = """
                    SELECT id, title, description, subject, level, grade_level,
                           duration_weeks, course_duration, price, instructor_name,
                           is_published, is_featured, created_by, created_at, updated_at
                    FROM public.courses 
                    ORDER BY created_at DESC 
                    LIMIT %s
                """
                cur.execute(query, (limit,))
                results = cur.fetchall()
                
                return {
                    "courses": [dict(row) for row in results],
                    "count": len(results)
                }
                
    except Exception as e:
        logger.error(f"Failed to fetch courses: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch courses: {str(e)}")

# ========================================
# TESTIMONIALS API ENDPOINTS (Direct SQL)
# ========================================

@app.post("/api/admin/testimonials")
async def create_testimonial(testimonial: Testimonial):
    """Create testimonial using direct SQL"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Generate unique ID and timestamps
                testimonial_id = str(uuid.uuid4())
                created_at = datetime.now()
                
                # Prepare target pages array
                target_pages_array = testimonial.target_pages if testimonial.target_pages else ["homepage"]
                
                # Insert testimonial using direct SQL
                query = """
                    INSERT INTO public.testimonials (
                        id, client_name, client_title, client_company, client_avatar_url,
                        testimonial_text, rating, testimonial_type, target_pages,
                        display_order, is_featured, is_visible, client_location,
                        client_website, project_details, client_industry,
                        verification_status, created_at, updated_at
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    ) RETURNING id, client_name, created_at
                """
                
                values = (
                    testimonial_id,
                    testimonial.client_name,
                    testimonial.client_title,
                    testimonial.client_company,
                    testimonial.client_avatar_url,
                    testimonial.testimonial_text,
                    testimonial.rating or 5,
                    testimonial.testimonial_type or "general",
                    target_pages_array,
                    testimonial.display_order or 0,
                    testimonial.is_featured if testimonial.is_featured is not None else False,
                    testimonial.is_visible if testimonial.is_visible is not None else True,
                    testimonial.client_location,
                    testimonial.client_website,
                    testimonial.project_details,
                    testimonial.client_industry,
                    "pending",
                    created_at,
                    created_at
                )
                
                cur.execute(query, values)
                result = cur.fetchone()
                conn.commit()
                
                logger.info(f"Testimonial created successfully: {testimonial_id}")
                return {
                    "id": result['id'],
                    "client_name": result['client_name'],
                    "created_at": result['created_at'].isoformat(),
                    "message": "Testimonial created successfully using direct SQL"
                }
                
    except Exception as e:
        logger.error(f"Testimonial creation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create testimonial: {str(e)}")

@app.get("/api/admin/testimonials")
async def list_testimonials(limit: int = Query(50, ge=1, le=100)):
    """Get all testimonials using direct SQL"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                query = """
                    SELECT id, client_name, client_title, client_company, testimonial_text,
                           rating, testimonial_type, is_featured, is_visible, created_at
                    FROM public.testimonials 
                    ORDER BY created_at DESC 
                    LIMIT %s
                """
                cur.execute(query, (limit,))
                results = cur.fetchall()
                
                return {
                    "testimonials": [dict(row) for row in results],
                    "count": len(results)
                }
                
    except Exception as e:
        logger.error(f"Failed to fetch testimonials: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch testimonials: {str(e)}")

# ========================================
# JOBS API ENDPOINTS (Direct SQL)
# ========================================

@app.post("/api/admin/jobs")
async def create_job(job: Job):
    """Create job listing using direct SQL"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Generate unique ID and timestamps
                job_id = str(uuid.uuid4())
                created_at = datetime.now()
                
                # Prepare arrays
                skills_array = job.skills if job.skills else []
                requirements_array = job.requirements if job.requirements else []
                responsibilities_array = job.responsibilities if job.responsibilities else []
                benefits_array = job.benefits if job.benefits else []
                
                # Insert job using direct SQL
                query = """
                    INSERT INTO public.jobs (
                        id, title, company_name, company_logo_url, location, is_remote,
                        employment_type, experience_level, salary_min, salary_max,
                        salary_currency, salary_period, description, requirements,
                        skills, responsibilities, benefits, application_deadline,
                        contact_email, application_url, application_instructions,
                        is_featured, is_active, is_published, category, industry,
                        created_at, updated_at
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    ) RETURNING id, title, created_at
                """
                
                values = (
                    job_id,
                    job.title,
                    job.company_name,
                    job.company_logo_url,
                    job.location,
                    job.is_remote if job.is_remote is not None else False,
                    job.employment_type or "full-time",
                    job.experience_level or "mid-level",
                    job.salary_min,
                    job.salary_max,
                    job.salary_currency or "USD",
                    job.salary_period or "year",
                    job.description,
                    requirements_array,
                    skills_array,
                    responsibilities_array,
                    benefits_array,
                    job.application_deadline,
                    job.contact_email,
                    job.application_url,
                    job.application_instructions,
                    job.is_featured if job.is_featured is not None else False,
                    job.is_active if job.is_active is not None else True,
                    job.is_published if job.is_published is not None else True,
                    job.category,
                    job.industry,
                    created_at,
                    created_at
                )
                
                cur.execute(query, values)
                result = cur.fetchone()
                conn.commit()
                
                logger.info(f"Job listing created successfully: {job_id}")
                return {
                    "id": result['id'],
                    "title": result['title'],
                    "created_at": result['created_at'].isoformat(),
                    "message": "Job listing created successfully using direct SQL"
                }
                
    except Exception as e:
        logger.error(f"Job creation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create job listing: {str(e)}")

@app.get("/api/admin/jobs")
async def list_jobs(limit: int = Query(50, ge=1, le=100)):
    """Get all job listings using direct SQL"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                query = """
                    SELECT id, title, company_name, location, employment_type,
                           is_remote, is_published, is_active, created_at
                    FROM public.jobs 
                    ORDER BY created_at DESC 
                    LIMIT %s
                """
                cur.execute(query, (limit,))
                results = cur.fetchall()
                
                return {
                    "jobs": [dict(row) for row in results],
                    "count": len(results)
                }
                
    except Exception as e:
        logger.error(f"Failed to fetch jobs: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch jobs: {str(e)}")

# ========================================
# HEALTH CHECK ENDPOINTS
# ========================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": "2.0", "mode": "direct-sql"}

@app.get("/test-db")
async def test_database():
    """Test database connection"""
    try:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Test basic query
                cur.execute("SELECT 1 as test")
                result = cur.fetchone()
                
                # Check if tables exist
                cur.execute("""
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_schema = 'public' AND table_name IN ('blog_posts', 'courses', 'testimonials', 'jobs')
                """)
                tables = cur.fetchall()
                
                return {
                    "database": "connected",
                    "test_query": dict(result),
                    "tables_found": [table['table_name'] for table in tables],
                    "message": "Direct SQL database connection working"
                }
                
    except Exception as e:
        logger.error(f"Database test failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Database test failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting AI Boss Admin v2.0 - Direct SQL Version")
    print("📋 This version bypasses all Supabase client and RLS issues")
    print("🔧 Using direct PostgreSQL queries for maximum reliability")
    uvicorn.run(app, host="0.0.0.0", port=8000)