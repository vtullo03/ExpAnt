import psycopg2
from flask import Flask, request, jsonify
import bcrypt
import jwt
from datetime import datetime, timedelta
from psycopg2 import sql
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity
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

@app.route('/update_match_profile', methods=["POST"])
@jwt_required()
def update_match_profile():
    username = get_jwt_identity()
    data = request.get_json()

    # Extract provided fields from request
    fields = ["bio", "images", "interests", "font_color", "background_color", "font_type", "pronouns", "university", "company", "field", "location", "first_name", "last_name"]
    updates = {field: data.get(field) for field in fields}

    if not any(value is not None for value in updates.values()):
        return jsonify({"message": "Please provide at least one profile detail"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Fetch existing profile
        cur.execute("SELECT * FROM match_profile WHERE username = %s", [username])
        existing_profile = cur.fetchone()

        if existing_profile:
            col_names = [item[0] for item in cur.description]

            existing_data = dict(zip(col_names, existing_profile))
            for field, value in updates.items():
                if value is not None:
                    existing_data[field] = value  # Use new value if provided

            update_fields = ", ".join([f"{field} = %s" for field in fields])
            update_values = [existing_data[field] for field in fields]

            cur.execute(
                f"UPDATE match_profile SET {update_fields} WHERE username = %s",
                update_values + [username]
            )
            message = "Profile updated successfully"
        else:
            insert_fields = ", ".join(["username"] + [f for f in fields])
            placeholders = ", ".join(["%s"] * (len(fields) + 1))
            insert_values = [username] + [updates[f] for f in fields]

            cur.execute(
                f"INSERT INTO match_profile ({insert_fields}) VALUES ({placeholders})",
                insert_values
            )
            message = "Profile created successfully"

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"message": message}), 201

    except Exception as e:
        print(e)
        return jsonify({"message": "Error processing profile"}), 500

@app.route('/match_profile/<other_username>', methods=["GET"])
@jwt_required()
def get_match_profile(other_username):
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("SELECT * FROM match_profile WHERE username = %s", [other_username])
        profile = cur.fetchone()

        if not profile:
            return jsonify({"message": "Profile not found"}), 404

        profile_data = {
            'bio': profile[1],
            'images': profile[2],
            'interests': profile[3],
            'font_color': profile[3],
            'background_color': profile[4],
            'font_type': profile[5],
            'pronouns': profile[6],
            'university': profile[7],
            'company': profile[8],
            'field': profile[9],
            'location': profile[9],
            'first_name': profile[10],
            'last_name': profile[11]
        }

        return jsonify(profile_data), 200

    except Exception as e:
        print(e)
        return jsonify({"message": "Error processing profile"}), 500

@app.route('/create_connection', methods=["POST"])
@jwt_required()
def create_connection():
    username = get_jwt_identity()
    data = request.get_json()
    connection_username = data.get("username")

    if not connection_username:
        return jsonify({"message": "Username for connection is required"}), 400

    if connection_username == username:
        return jsonify({"message": "Cannot connect with yourself"}), 400

    user_1, user_2 = sorted([username, connection_username])

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("INSERT INTO connections (user1_username, user2_username) VALUES (%s, %s)", (user_1, user_2))

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"message": "Connection created successfully"}), 201

    except Exception as e:
        print(e)
        return jsonify({"message": "Error processing connection"}), 500

@app.route('/connections', methods=["GET"])
@jwt_required()
def get_connections():
    username = get_jwt_identity()

    try:
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

        return jsonify({"connections": connections}), 200

    except Exception as e:
        print(e)
        return jsonify({"message": "Error fetching connections"}), 500

@app.route('/create_message', methods=["POST"])
@jwt_required()
def create_message():
    username = get_jwt_identity()
    data = request.get_json()
    receiver_username = data.get("username")
    message = data.get("message")

    if not receiver_username or not message:
        return jsonify({"message": "Please provide both username and message"}), 400

    if receiver_username == username:
        return jsonify({"message": "Cannot message yourself"}), 400

    if message == "":
        return jsonify({"message": "Cannot send blank message"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
                INSERT INTO messages (user_1, user_2, messages)
                VALUES (%s, %s, %s)
            """, (username, receiver_username, message))

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"message": "Message created!"}), 201

    except Exception as e:
        print(e)
        return jsonify({"message": "Failed to send message"}), 500

@app.route('/messages/<other_username>', methods=["GET"])
@jwt_required()
def get_messages(other_username):
    current_user = get_jwt_identity()

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            SELECT user_1, user_2, messages, created_at
            FROM messages
            WHERE (user_1 = %s AND user_2 = %s)
               OR (user_1 = %s AND user_2 = %s)
            ORDER BY created_at ASC
        """, (current_user, other_username, other_username, current_user))

        rows = cur.fetchall()
        cur.close()
        conn.close()

        messages = [
            {
                "from": row[0],
                "to": row[1],
                "message": row[2],
                "timestamp": row[3].isoformat()
            }
            for row in rows
        ]

        return jsonify({"messages": messages}), 200

    except Exception as e:
        print(e)
        return jsonify({"message": "Could not retrieve messages"}), 500

@app.route('/create_forum', methods=["POST"])
@jwt_required()
def create_forum():
    username = get_jwt_identity()
    data = request.get_json()
    title = data.get("title")
    description = data.get("description")
    images = data.get("images")

    if not title or not description:
        return jsonify({"message": "Need title or description"}), 500

    if title == " " or description == " ":
        return jsonify({"message": "Title or description cannot be blank"}), 500

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            INSERT INTO forums (username, title, description, images)
            VALUES (%s, %s, %s, %s)
            """, (username, title, description, images))

        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'message': 'Forum post created successfully'}), 201

    except Exception as e:
        print(e)
        return jsonify({"message": "Could not create forum post"}), 500

@app.route('/create_comment/<forum_id>', methods=["POST"])
@jwt_required()
def create_comment(forum_id):
    username = get_jwt_identity()
    data = request.get_json()
    description = data.get("description")
    images = data.get("images")

    if not description:
        return jsonify({"message": "Need description"}), 500

    if description == " ":
        return jsonify({"message": "Description cannot be blank"}), 500

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            INSERT INTO forum_comments (username, forum_id, description, images)
            VALUES (%s, %s, %s, %s)
            """, (username, forum_id, description, images))

        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'message': 'Comment created successfully'}), 201

    except Exception as e:
        print(e)
        return jsonify({"message": "Could not create comment"}), 500

@app.route('/get_forum_ids/<other_username>', methods=["GET"])
@jwt_required()
def get_forum_ids(other_username):

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            SELECT id FROM forums WHERE username = %s
        """, (other_username,))

        forum_ids = [row[0] for row in cur.fetchall()]

        cur.close()
        conn.close()

        return jsonify({'forum_ids': forum_ids}), 200

    except Exception as e:
        print(e)
        return jsonify({"message": "Could not retrieve forum IDs"}), 500

@app.route('/forums/<forum_id>', methods=["GET"])
@jwt_required()
def get_forum(forum_id):
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
                    SELECT username, title, description, images, created_time 
                    FROM forums 
                    WHERE id = %s
                """, (forum_id,))
        forum = cur.fetchone()

        if not forum:
            cur.close()
            conn.close()
            return jsonify({"message": "Forum not found"}), 404

        cur.execute("""
            SELECT username, description, created_time 
            FROM forum_comments 
            WHERE forum_id = %s
        """, (forum_id,))
        comments = cur.fetchall()

        forum_data = {
            'username': forum[0],
            'title': forum[1],
            'description': forum[2],
            'images': forum[3],
            'created_time': forum[4],
            'comments': [
                {
                    'username': c[0],
                    'description': c[1],
                    'created_at': c[2].isoformat()
                } for c in comments
            ]
        }

        return jsonify(forum_data), 200

    except Exception as e:
        print(e)
        return jsonify({"message": "Could not retrieve forum and comments"}), 500

    cur.close()
    conn.close()

if __name__ == "__main__":
    app.run(debug=True)