import os
from datetime import timedelta
import bcrypt
import psycopg2
from psycopg2 import sql
from fastapi import FastAPI, HTTPException, Depends
from fastapi_jwt_auth import AuthJWT
from fastapi_jwt_auth.exceptions import AuthJWTException
from pydantic import BaseModel
from fastapi.responses import JSONResponse

app = FastAPI()

DB_URL = "postgresql://neondb_owner:npg_5hJDayeMm9jU@ep-shiny-credit-a8a5akue.eastus2.azure.neon.tech/neondb?sslmode=require"

# Connect to the database
def get_db_connection():
    conn = psycopg2.connect(DB_URL)
    return conn

# MODELS
# Settings -- JWT secret key for auth
class Settings(BaseModel):
    jwt_secret_key: str = os.getenv("JWT_SECRET_KEY", "default-secret")

# UserAuth -- User info for login/registering
class UserAuth(BaseModel):
    username: str
    password: str

# Load JWT
@AuthJWT.load_config
def get_config():
    return Settings()

# POST for register
@app.post("/register")
async def register(user: UserAuth):

    # Make sure username and password were put in
    if not user.username or not user.password:
        raise HTTPException(status_code=400, detail="Please provide both username and password")

    # Hash the password -- byte string
    password_hash = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())

    # Insert the new user into the database
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            sql.SQL("INSERT INTO jobforceusers (username, password_hash) VALUES (%s, %s)"),
            [user.username, password_hash.decode('utf-8')]
        )

        conn.commit()
        cur.close()
        conn.close()
        return {"message": "User registered successfully"}

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Error registering user")

# POST for login
@app.post("/login")
async def login(user: UserAuth, Authorize: AuthJWT = Depends()):

    # Make sure username and password were put in
    if not user.username or not user.password:
        raise HTTPException(status_code=400, detail="Please provide both username and password")

    try:

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
            raise HTTPException(status_code=401, detail="Invalid username or password")

        # Compare the hashed password
        stored_password_hash = result[0].encode('utf-8')

        if bcrypt.checkpw(user.password.encode('utf-8'), stored_password_hash):
            # Create JWT token that expires in 1 hour
            access_token = Authorize.create_access_token(
                subject=user.username,
                expires_time=timedelta(hours=1)
            )
            return {"access_token": access_token}
        else:
            raise HTTPException(status_code=401, detail="Invalid username or password")

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Error logging in")