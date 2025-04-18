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
def update_match_profile(profile: MatchProfile, Authorize: AuthJWT = Depends()):

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