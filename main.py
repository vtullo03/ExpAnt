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