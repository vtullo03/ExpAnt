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

        cur.execute(
            sql.SQL("SELECT password_hash FROM jobforceusers WHERE username = %s"),
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

        # Compare the provided password with the stored hash
        if bcrypt.checkpw(user.password.encode('utf-8'), stored_password_hash):
            # If the password matches, generate a JWT token
            access_token = Authorize.create_access_token(
                subject=user.username,
                expires_time=timedelta(hours=1)
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
async def update_match_profile(profile: MatchProfile, Authorize: AuthJWT = Depends()):

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
async def get_match_profile(other_username: str, Authorize: AuthJWT = Depends()):

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
async def create_connection(connection: Connection, Authorize: AuthJWT = Depends()):

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
async def get_connections(Authorize: AuthJWT = Depends()):

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
async def create_forum(post: ForumPost, Authorize: AuthJWT = Depends()):

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
async def create_comment(forum_id: int, comment: ForumComment, Authorize: AuthJWT = Depends()):
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
async def get_forum_ids(other_username: str, Authorize: AuthJWT = Depends()):

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
async def get_feed(Authorize: AuthJWT = Depends()):

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

        rows = cur.fetchall()
        posts = []

        # For each user get forum posts
        for user in rows:

            cur.execute("""
                        SELECT id FROM forums WHERE username = %s
                    """, (user,))

            forum_ids = [row[0] for row in cur.fetchall()]
            posts.append(forum_ids)

        cur.close()
        conn.close()

        return JSONResponse(content=posts, status_code=200)

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Could not get feed")

# GET for matches
@app.get("/matches_today")
async def get_matches(Authorize: AuthJWT = Depends()):

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