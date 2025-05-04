import os
import logging
from datetime import timedelta
import bcrypt
import psycopg2
from psycopg2 import sql
from fastapi import FastAPI, HTTPException, Depends
from fastapi_jwt_auth import AuthJWT
from fastapi_jwt_auth.exceptions import AuthJWTException
from pydantic import BaseModel
from fastapi.responses import JSONResponse
from typing import Optional, List

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

DB_URL = "postgresql://neondb_owner:npg_5hJDayeMm9jU@ep-shiny-credit-a8a5akue.eastus2.azure.neon.tech/neondb?sslmode=require"

# Connect to the database
def get_db_connection():
    conn = psycopg2.connect(DB_URL)
    return conn

# MODELS
# Settings -- JWT secret key for auth
class Settings(BaseModel):
    authjwt_secret_key: str = "super-secret-key"

# Load JWT
@AuthJWT.load_config
def get_config():
    logger.debug("Loading JWT Config...")  # Replaced print with logging at debug level
    return Settings()

# UserAuth -- User info for login/registering
class UserAuth(BaseModel):
    username: str
    password: str

class MatchProfile(BaseModel):
    bio: Optional[str] = None
    images: Optional[List[str]] = None
    interests: Optional[List[str]] = None
    font_color: Optional[str] = None
    background_color: Optional[str] = None
    font_type: Optional[str] = None
    pronouns: Optional[str] = None
    university: Optional[str] = None
    company: Optional[str] = None
    field: Optional[str] = None
    location: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None

class Connection(BaseModel):
    username: str

class ForumPost(BaseModel):
    title: str
    description: str
    images: Optional[List[str]] = None

class ForumComment(BaseModel):
    description: str
    images: Optional[List[str]] = None

class JobPosting(BaseModel):
    title: str
    description: str
    location: Optional[str] = None
    salary: Optional[int] = None
    company_website_link: Optional[str] = None

class RecommendedJob(BaseModel):
    username: str
    job_id: int

class Message(BaseModel):
    username: str
    message: str

def require_worker(Authorize: AuthJWT = Depends()):
    Authorize.jwt_required()
    user_type = Authorize.get_raw_jwt().get("user_type")
    if user_type != "worker":
        raise HTTPException(status_code=403, detail="Access restricted to worker users only")
    return Authorize

def require_organization(Authorize: AuthJWT = Depends()):
    Authorize.jwt_required()
    user_type = Authorize.get_raw_jwt().get("user_type")
    if user_type != "official":
        raise HTTPException(status_code=403, detail="Access restricted to official organizations only")
    return Authorize

# POST for register
@app.post("/register")
async def register(user: UserAuth):

    # Make sure username and password were put in
    if not user.username or not user.password:
        logger.warning("Username or password missing during registration attempt")  # Log warning if data is missing
        raise HTTPException(status_code=400, detail="Please provide both username and password")

    # Hash the password as bytes
    password_hash = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())

    # Insert the new user into the database
    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Insert the password_hash as bytes
        cur.execute(
            sql.SQL("INSERT INTO jobforceusers (username, password_hash) VALUES (%s, %s)"),
            [user.username, psycopg2.Binary(password_hash)]  # Store as binary
        )

        conn.commit()
        cur.close()
        conn.close()
        logger.info(f"User {user.username} registered successfully")  # Log success
        return {"message": "User registered successfully"}

    except Exception as e:
        logger.error(f"Error registering user: {e}")  # Log error with exception
        raise HTTPException(status_code=500, detail="Error registering user")

# POST for register
@app.post("/organization")
async def organization(user: UserAuth):

    # Make sure username and password were put in
    if not user.username or not user.password:
        logger.warning("Username or password missing during organization creation attempt")  # Log warning if data is missing
        raise HTTPException(status_code=400, detail="Please provide both username and password")

    # Hash the password as bytes
    password_hash = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())

    # Insert the new user into the database
    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Insert the password_hash as bytes
        cur.execute(
            sql.SQL("INSERT INTO official_company (username, password_hash) VALUES (%s, %s)"),
            [user.username, psycopg2.Binary(password_hash)]  # Store as binary
        )

        conn.commit()
        cur.close()
        conn.close()
        logger.info(f"User {user.username} registered successfully")  # Log success
        return {"message": "User registered successfully"}

    except Exception as e:
        logger.error(f"Error registering user: {e}")  # Log error with exception
        raise HTTPException(status_code=500, detail="Error registering user")

# POST for login
@app.post("/login")
async def login(user: UserAuth, Authorize: AuthJWT = Depends()):

    # Make sure username and password were put in
    if not user.username or not user.password:
        logger.warning("Username or password missing during login attempt")  # Log warning if data is missing
        raise HTTPException(status_code=400, detail="Please provide both username and password")

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # First check if the user is a normal worker
        cur.execute(
            sql.SQL("SELECT password_hash, 'worker' as user_type FROM jobforceusers WHERE username = %s"),
            [user.username]
        )
        result = cur.fetchone()

        # Then check if it's an official organization if it's not a normal worker
        # This may break in the edge case that a worker and organization have the exact same user and password
        # But by setting user_type, we can now auth which user connected
        if result is None:
            cur.execute(
                sql.SQL("SELECT password_hash, 'official' as user_type FROM official_company WHERE username = %s"),
                [user.username]
            )
            result = cur.fetchone()

        cur.close()
        conn.close()

        if result is None:
            logger.warning(f"Login failed: Invalid username {user.username}")  # Log failed login attempt
            raise HTTPException(status_code=401, detail="Invalid username or password")

        # PostgreSQL returns BYTEA as memoryview because they hate all programmers
        stored_password_hash = bytes(result[0]) # convert memoryview to bytes
        user_type = result[1]

        # Compare the provided password with the stored hash
        if bcrypt.checkpw(user.password.encode('utf-8'), stored_password_hash):
            # If the password matches, generate a JWT token
            access_token = Authorize.create_access_token(
                subject=user.username,
                expires_time=timedelta(hours=1),
                user_claims={"user_type": user_type}
            )
            logger.info(f"User {user.username} logged in successfully")  # Log successful login
            return {"access_token": access_token}
        else:
            # If the password does not match
            logger.warning(f"Login failed: Invalid password for user {user.username}")  # Log failed login attempt
            raise HTTPException(status_code=401, detail="Invalid username or password")

    except Exception as e:
        logger.error(f"Error logging in: {e}")  # Log error with exception
        raise HTTPException(status_code=500, detail="Error logging in")

# POST for updating match profile
@app.post("/update_match_profile")
async def update_match_profile(profile: MatchProfile, Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    # Turn model into dictionary -- throw error if there's nothing
    updates = profile.dict()
    if not any(v is not None for v in updates.values()):
        logger.warning(f"Update attempt with no data by user: {username}")
        raise HTTPException(status_code=400, detail="Please provide at least one profile detail")

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Fetch existing profile
        cur.execute("SELECT * FROM match_profile WHERE username = %s", [username])
        existing_profile = cur.fetchone()

        if existing_profile:
            # Profile found -- update it
            # Get names of fields
            col_names = [item[0] for item in cur.description]
            existing_data = dict(zip(col_names, existing_profile))

            for field, value in updates.items():
                if value is not None:
                    existing_data[field] = value  # Use new value if provided

            update_fields = ", ".join([f"{field} = %s" for field in updates])
            update_values = [existing_data[field] for field in updates]

            # Update with any new values -- does not overwrite old ones
            cur.execute(
                f"UPDATE match_profile SET {update_fields} WHERE username = %s",
                update_values + [username]
            )

            message = "Profile updated successfully"
            logger.info(f"Profile updated for user: {username}")

        else:
            # No profile found -- create new profile
            insert_fields = ", ".join(["username"] + [f for f in updates])
            placeholders = ", ".join(["%s"] * (len(updates) + 1))
            insert_values = [username] + [updates[f] for f in updates]

            cur.execute(
                f"INSERT INTO match_profile ({insert_fields}) VALUES ({placeholders})",
                insert_values
            )

            message = "Profile created successfully"
            logger.info(f"Profile created for user: {username}")

        conn.commit()
        cur.close()
        conn.close()

        return {"message": message}

    except Exception as e:
        logger.error(f"Error processing match profile for user {username}: {e}")
        raise HTTPException(status_code=500, detail="Error processing profile")


# GET for match profile
@app.get("/match_profile/{other_username}")
async def get_match_profile(other_username: str, Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("SELECT * FROM match_profile WHERE username = %s", [other_username])
        profile = cur.fetchone()

        if not profile:
            logger.warning(f"Profile not found for username: {other_username}")  # Log the missing profile
            raise HTTPException(status_code=404, detail="Profile not found")

        col_names = [item[0] for item in cur.description]
        data = dict(zip(col_names, profile))

        cur.close()
        conn.close()

        return JSONResponse(content=data, status_code=200)

    except Exception as e:
        logger.error(f"Error fetching profile for {other_username}: {e}")
        raise HTTPException(status_code=500, detail="Error processing profile")

# POST for connection creation
@app.post("/create_connection")
async def create_connection(connection: Connection, Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()
    connection_username = connection.username

    if not connection_username:
        logger.warning(f"Connection attempt without username by {username}")
        raise HTTPException(status_code=400, detail="Username for connection is required")

    if connection_username == username:
        logger.warning(f"User {username} attempted to connect with themselves")
        raise HTTPException(status_code=400, detail="Cannot connect with yourself")

    user_1, user_2 = sorted([username, connection_username])

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("INSERT INTO connections (user1_username, user2_username) VALUES (%s, %s)", (user_1, user_2))

        conn.commit()
        cur.close()
        conn.close()

        logger.info(f"Connection created between {user_1} and {user_2}")
        return JSONResponse(content={"message": "Connection created successfully"}, status_code=201)

    except Exception as e:
        logger.error(f"Error creating connection between {user_1} and {user_2}: {e}")
        raise HTTPException(status_code=500, detail="Error processing connection")

# GET for connections
@app.get("/connections")
async def get_connections(Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
                            SELECT 
                                CASE 
                                    WHEN user1_username = %s THEN user2_username
                                    ELSE user1_username
                                END AS connection_username
                            FROM connections
                            WHERE user1_username = %s OR user2_username = %s
                        """, (username, username, username))

        rows = cur.fetchall()
        cur.close()
        conn.close()

        connections = [row[0] for row in rows]
        return JSONResponse(content=connections, status_code=200)

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Error fetching connections")

# POST for forum creation
@app.post("/create_forum")
async def create_forum(post: ForumPost, Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            INSERT INTO forums (username, title, description, images)
            VALUES (%s, %s, %s, %s)
        """, (username, post.title, post.description, post.images))

        conn.commit()
        cur.close()
        conn.close()

        logger.info(f"Forum post created by user: {username}")
        return {"message": "Forum post created successfully"}

    except Exception as e:
        logger.error(f"Error creating forum post for user {username}: {e}")
        raise HTTPException(status_code=500, detail="Could not create forum post")

# POST for comment creation
@app.post("/create_comment/{forum_id}")
async def create_comment(forum_id: int, comment: ForumComment, Authorize: AuthJWT = Depends(require_worker)):
    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    # Check for blank comments
    if comment.description == "":
        logger.warning(f"Blank comment attempted by user: {username}")
        raise HTTPException(status_code=400, detail="Description cannot be blank")

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
                INSERT INTO forum_comments (username, forum_id, description, images)
                VALUES (%s, %s, %s, %s)
            """, (username, forum_id, comment.description, comment.images))

        conn.commit()
        cur.close()
        conn.close()

        logger.info(f"Comment created on forum {forum_id} by user: {username}")
        return {"message": "Comment created successfully"}

    except Exception as e:
        logger.error(f"Error creating comment for user {username} on forum {forum_id}: {e}")
        raise HTTPException(status_code=500, detail="Could not create comment")

# GET for forum via username
@app.get("/get_forum_ids/{other_username}")
async def get_forum_ids(other_username: str, Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            SELECT id FROM forums WHERE username = %s
        """, (other_username,))

        forum_ids = [row[0] for row in cur.fetchall()]

        cur.close()
        conn.close()

        return JSONResponse(content={"forum_ids": forum_ids}, status_code=200)

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Could not retrieve forum IDs")

# GET for forums via ID
@app.get("/forums/{forum_id}")
async def get_forum(forum_id: str, Authorize: AuthJWT = Depends()):

    Authorize.jwt_required()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Fetch the forum itself
        cur.execute("""
            SELECT username, title, description, images, created_time 
            FROM forums 
            WHERE id = %s
        """, (forum_id,))
        forum = cur.fetchone()

        if not forum:
            raise HTTPException(status_code=404, detail="Forum not found")

        # Fetch the forum comments
        cur.execute("""
            SELECT username, description, created_time 
            FROM forum_comments 
            WHERE forum_id = %s
        """, (forum_id,))
        comments = cur.fetchall()

        # Build response as json
        forum_data = {
            "username": forum[0],
            "title": forum[1],
            "description": forum[2],
            "images": forum[3],
            "created_time": forum[4].isoformat(),
            "comments": [
                {
                    "username": c[0],
                    "description": c[1],
                    "created_at": c[2].isoformat()
                } for c in comments
            ]
        }

        cur.close()
        conn.close()

        return JSONResponse(content=forum_data, status_code=200)

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Could not retrieve forum and comments")

# GET for forum posts via usernames from connection
@app.get("/feed")
async def get_feed(Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Get all usernames from connections
        cur.execute("""
            SELECT 
                CASE 
                    WHEN user1_username = %s THEN user2_username
                    ELSE user1_username
                END AS connection_username
            FROM connections
            WHERE user1_username = %s OR user2_username = %s
        """, (username, username, username))

        # Extract connection usernames and include the user's own username
        rows = cur.fetchall()
        usernames = [row[0] for row in rows]
        usernames.append(username)  # Include user's own posts

        posts = []

        # For each user get forum posts
        for user in usernames:

            cur.execute("""
                SELECT id, username, title, description, created_time, images
                FROM forums
                WHERE username = %s
                ORDER BY created_time DESC
            """, (user,))

            user_posts = cur.fetchall()
            for post in user_posts:
                posts.append({
                    "id": post[0],
                    "username": post[1],
                    "title": post[2],
                    "content": post[3],
                    "created_at": post[4].isoformat(),  # Ensure datetime is JSON serializable
                    "images": post[5]
                })

        cur.close()
        conn.close()

        return JSONResponse(content=posts, status_code=200)

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Could not get feed")

# GET for matches
@app.get("/matches_today")
async def get_matches(Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Get current user field, location, and interests
        cur.execute("""
                    SELECT field, location, interests 
                    FROM match_profile 
                    WHERE username = %s
                """, (username,))
        result = cur.fetchone()

        if not result:
            raise HTTPException(status_code=404, detail="No matches found")

        field, location, interests = result
        # Because this is an optional field and we wanna give prio -- account for when it's empty
        if interests is None:
            interests = []

        # Have to put username like a million times to check if users are connected
        # Selects 10 USERS ONLY with same field in same area -- gets prio to users with same interests
        cur.execute("""
            SELECT *, 
                CARDINALITY(ARRAY(SELECT UNNEST(interests) INTERSECT SELECT UNNEST(%s::text[]))) AS shared_interest_count
            FROM match_profile
            WHERE field = %s 
              AND location = %s 
              AND username != %s
              AND username NOT IN (
                  SELECT CASE
                      WHEN user1_username = %s THEN user2_username
                      ELSE user1_username
                  END AS connection_username
                  FROM connections
                  WHERE user1_username = %s OR user2_username = %s
              )
            ORDER BY shared_interest_count DESC NULLS LAST
            LIMIT 10
        """, (interests, field, location, username, username, username, username))
        col_names = [desc[0] for desc in cur.description]

        matches = cur.fetchall()
        col_names = [desc[0] for desc in cur.description]
        match_profiles = [dict(zip(col_names, match)) for match in matches]

        cur.close()
        conn.close()

        return JSONResponse(content=match_profiles, status_code=200)

    except Exception as e:
        logger.error(f"Error fetching matches for {username}: {e}")
        raise HTTPException(status_code=500, detail="Error fetching matches")

# POST for job postings
@app.post("/create_job_posting")
async def create_job_posting(post: JobPosting, Authorize: AuthJWT = Depends(require_organization)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            INSERT INTO job_postings (username, title, description, location, salary, company_website_link)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (username, post.title, post.description, post.location, post.salary, post.company_website_link))

        conn.commit()
        cur.close()
        conn.close()

        logger.info(f"Job posting created by organization: {username}")
        return {"message": "Job posting created successfully"}

    except Exception as e:
        logger.error(f"Error creating job posting for organization {username}: {e}")
        raise HTTPException(status_code=500, detail="Could not create job posting")


# POST for job recommendations
@app.post("/recommend_job")
async def recommend_job(job: RecommendedJob, Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()
    other_username = job.username
    job_id = job.job_id

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Check if other_username is a connection of the authenticated user
        # Makes sure you can't recommend jobs to random users
        cur.execute("""
                    SELECT 
                        CASE 
                            WHEN user1_username = %s THEN user2_username
                            ELSE user1_username
                        END AS connection_username
                    FROM connections
                    WHERE user1_username = %s OR user2_username = %s
                """, (username, username, username))
        connections = cur.fetchall()
        connection_usernames = [connection[0] for connection in connections]

        if other_username not in connection_usernames:
            # If other_username is not in the list of connections, raise an error
            raise HTTPException(status_code=400, detail="You are not connected with this user")

        cur.execute("SELECT * FROM recommended_jobs WHERE username = %s", [other_username])
        existing_job_recs = cur.fetchone()

        if existing_job_recs:
            # User has recommended jobs, add to i
            cur.execute(
                "UPDATE recommended_jobs SET job_ids = array_append(job_ids, %s) WHERE username = %s",
                [job_id, other_username]
            )

            message = "Job recommendation updated successfully"
            logger.info(f"Job recommendation updated for user: {other_username}")

        else:
            # No existing job recommendations, create a new one
            insert_fields = ["username", "job_ids"]
            placeholders = ", ".join(["%s"] * len(insert_fields))
            insert_values = [other_username, [job_id]]  # Wrap job_id in a list to create an array

            cur.execute(
                f"INSERT INTO recommended_jobs ({', '.join(insert_fields)}) VALUES ({placeholders})",
                insert_values
            )

            message = "Job recommendations created successfully"
            logger.info(f"Job recommendations created for user: {other_username}")

        conn.commit()
        cur.close()
        conn.close()

        return {"message": message}

    except Exception as e:
        logger.error(f"Error processing job recommendations for user {other_username}: {e}")
        raise HTTPException(status_code=500, detail="Error processing job recommendations")

# GET for showing jobs -- workers
@app.get("/job_postings")
async def get_job_listings(Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Get all the jobs there were already recommended by other users to the user
        cur.execute("SELECT job_ids FROM recommended_jobs WHERE username = %s", [username])
        existing_job_recs = cur.fetchone()

        # Make the list empty if no recs -- we will fill this
        if existing_job_recs is None:
            # Create a new empty recommendation entry
            cur.execute("""
                        INSERT INTO recommended_jobs (username, job_ids)
                        VALUES (%s, %s)
                    """, (username, []))
            conn.commit()
            current_job_ids = []
        else:
            current_job_ids = existing_job_recs[0] or []

        job_ids = set(current_job_ids) # sets auto remove duplicate -- could be annoying to the user

        if len(current_job_ids) < 10:
            # Check how many more jobs to recommend are needed
            required_jobs = 10 - len(current_job_ids)

            cur.execute("""
                            SELECT id
                            FROM job_postings
                            WHERE location = (SELECT location FROM match_profile WHERE username = %s)
                            AND NOT (id = ANY(%s))
                            LIMIT %s
                        """, (username, list(job_ids), required_jobs))

            additional_jobs = cur.fetchall()

            # Add new jobs to the set
            new_job_ids = [job[0] for job in additional_jobs]
            job_ids.update(new_job_ids)

            # Save updated job_ids back to the table
            cur.execute("""
                            UPDATE recommended_jobs
                            SET job_ids = %s
                            WHERE username = %s
                        """, (list(job_ids), username))
            conn.commit()

        # Get all job posting info from ids
        cur.execute("""
            SELECT *
            FROM job_postings
            WHERE id = ANY(%s)
        """, (list(job_ids),))
        job_postings = cur.fetchall()

        columns = [desc[0] for desc in cur.description]
        job_postings_dicts = [dict(zip(columns, row)) for row in job_postings]

        cur.close()
        conn.close()

        return {"job_postings": job_postings_dicts}

    except Exception as e:
        logger.error(f"Error fetching recommended jobs for {username}: {e}")
        raise HTTPException(status_code=500, detail="Error fetching recommended jobs")

# GET for showing jobs -- organizations
@app.get("/company_job_postings")
async def get_job_listings(Authorize: AuthJWT = Depends(require_organization)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        # Get all job posting info from ids
        cur.execute("""
                    SELECT *
                    FROM job_postings
                    WHERE username = %s
                """, (username,))
        job_postings = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
        job_postings_dicts = [dict(zip(columns, row)) for row in job_postings]

        cur.close()
        conn.close()

        return {"job_postings": job_postings_dicts}

    except Exception as e:
        logger.error(f"Error fetching job postings for {username}: {e}")
        raise HTTPException(status_code=500, detail="Error fetching job postings")

# GET for getting user type
@app.get("/user_type")
async def get_user_type(Authorize: AuthJWT = Depends()):

    Authorize.jwt_required()
    user_type = Authorize.get_raw_jwt().get("user_type")

    return {"user_type": user_type}

# POST for message creation
@app.post("/create_message")
async def create_message(data: Message, Authorize: AuthJWT = Depends(require_worker)):
    username = Authorize.get_jwt_subject()
    receiver_username = data.username
    message = data.message

    if not receiver_username or not message:
        raise HTTPException(status_code=400, detail="Please provide both username and message")

    if receiver_username == username:
        raise HTTPException(status_code=400, detail="Cannot message yourself")

    if message.strip() == "":
        raise HTTPException(status_code=400, detail="Cannot send blank message")

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            INSERT INTO messages (user_1, user_2, messages)
            VALUES (%s, %s, %s)
        """, (username, receiver_username, message))

        conn.commit()
        cur.close()
        conn.close()

        return {"message": "Message created!"}

    except Exception as e:
        print(f"Error sending message from {username} to {receiver_username}: {e}")
        raise HTTPException(status_code=500, detail="Failed to send message")

# GET for messages

@app.get("/messages/{other_username}")
async def get_messages(other_username: str, Authorize: AuthJWT = Depends(require_worker)):

    Authorize.jwt_required()
    username = Authorize.get_jwt_subject()

    try:
        # Connect to the database
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            SELECT user_1, user_2, messages, created_at
            FROM messages
            WHERE (user_1 = %s AND user_2 = %s)
               OR (user_1 = %s AND user_2 = %s)
            ORDER BY created_at ASC
        """, (username, other_username, other_username, username))

        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
        messages = [dict(zip(columns, row)) for row in rows]

        # Format timestamp as ISO string
        for msg in messages:
            msg["created_at"] = msg["created_at"].isoformat()

        cur.close()
        conn.close()

        return {"messages": messages}

    except Exception as e:
        logger.error(f"Error retrieving messages between {username} and {other_username}: {e}")
        raise HTTPException(status_code=500, detail="Could not retrieve messages")