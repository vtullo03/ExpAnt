﻿import psycopg2
from flask import Flask, request, jsonify
import bcrypt
import jwt
from datetime import datetime, timedelta
from psycopg2 import sql
from flask_jwt_extended import JWTManager, jwt_required, create_access_token
import os

app = Flask(__name__)

# Secret key for JWT signing
app.config['JWT_SECRET_KEY'] = os.getenv("JWT_SECRET_KEY")
jwt_manager = JWTManager(app)

# Neon SQL Database connection string
DB_URL = os.getenv("\ufeffDATABASE_URL")

def get_db_connection():
    conn = psycopg2.connect(DB_URL)
    return conn

@app.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    # Validate the input
    if not username or not password:
        return jsonify({"message": "Please provide all fields"}), 400

    # Hash the password using bcrypt
    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    # Insert the new user into the database
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            sql.SQL("INSERT INTO jobforceusers (username, password_hash) VALUES (%s, %s)"),
            [username, password_hash.decode('utf-8')]
        )

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"message": "User registered successfully"}), 201

    except Exception as e:
        print(e)
        return jsonify({"message": "Error registering user"}), 500

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    # Validate the input
    if not username or not password:
        return jsonify({"message": "Please provide both username and password"}), 400

    # Check if the user exists in the database
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            sql.SQL("SELECT password_hash FROM jobforceusers WHERE username = %s"),
            [username]
        )

        user = cur.fetchone()
        cur.close()
        conn.close()

        if user is None:
            return jsonify({"message": "Invalid username or password"}), 401

        # Compare the hashed password
        stored_password_hash = user[0].encode('utf-8')

        if bcrypt.checkpw(password.encode('utf-8'), stored_password_hash):
            # Create JWT token that expires in 1 hour
            access_token = create_access_token(identity=username, fresh=True, expires_delta=timedelta(hours=1))
            return jsonify({"access_token": access_token}), 200
        else:
            return jsonify({"message": "Invalid username or password"}), 401

    except Exception as e:
        print(e)
        return jsonify({"message": "Error logging in"}), 500

@app.route('/match_profile', methods=["POST"])
@jwt_required() 
def match_profile():
    username = get_jwt_identity()
    data = request.get_json()
    bio = data.get("bio")
    images = data.get("images")
    interests = data.get("interests")
    font_color = data.get("font_color")
    background_color = data.get("background_color")
    font_type = data.get("font_type")

    # Optionally validate input
    if not any([bio, images, interests, font_color, background_color, font_type]):
        return jsonify({"message": "Please provide at least one profile detail"}), 400

    # Insert or update user profile in the database
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Check if user already has a profile entry
        cur.execute(
            sql.SQL("SELECT username FROM match_profile WHERE username = %s"),
            [username]
        )

        existing_profile = cur.fetchone()

        if existing_profile:
            # If the profile exists, update it (optional, if you want to allow updates)
            cur.execute(
                sql.SQL("UPDATE match_profile SET bio = %s, images = %s, interests = %s, font_color = %s, background_color = %s, font_type = %s WHERE username = %s"),
                [bio, images, interests, font_color, background_color, font_type, username]
            )
            message = "Profile updated successfully"
        else:
            # If no profile exists, insert a new profile
            cur.execute(
                sql.SQL("INSERT INTO match_profile (username, bio, images, interests, font_color, background_color, font_type) VALUES (%s, %s, %s, %s, %s, %s, %s)"),
                [username, bio, images, interests, font_color, background_color, font_type]
            )
            message = "Profile created successfully"

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"message": message}), 201

    except Exception as e:
        print(e)
        return jsonify({"message": "Error processing profile"}), 500