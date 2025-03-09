import bcrypt
import psycopg2
from fastapi import Depends

from database import engine, get_db
from models import User
from sqlalchemy import insert

def create_user():
    username = input("enter a username (6 chars): ")
    if len(username) < 6:
        print("nahh...")
        return

    password = input("Enter a pass: ")
    if len(password) < 6:
        print("nahhh")
        return

    hashed_password = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
    account_type = 1

    new_user = User(username = username, accounttype = account_type, password_hash = hashed_password, bio = '',
                    company = '', field = '', position = '', experience = 0)

    db_generator = get_db()
    db = next(db_generator)
    db.add(new_user)
    db.commit()

if __name__ == "__main__":
    create_user()