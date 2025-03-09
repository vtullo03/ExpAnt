from sqlalchemy import Column, Integer, ForeignKey, DateTime, Boolean, Text
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    username = Column(Text, primary_key=True, index=True)
    accounttype = Column(Integer)
    password_hash = Column(Text)
    bio = Column(Text)
    company = Column(Text)
    field = Column(Text)
    position = Column(Text)
    experience = Column(Integer)