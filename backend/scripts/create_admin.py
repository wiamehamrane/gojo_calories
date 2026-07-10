#!/usr/bin/env python3
"""Create or promote an admin user.

Usage:
    python scripts/create_admin.py admin@gojocalories.com MySecurePassword "Admin Name"

Or promote an existing user:
    python scripts/create_admin.py admin@gojocalories.com --promote
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
from models import User
from security import get_password_hash


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    email = sys.argv[1]
    promote_only = "--promote" in sys.argv

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()

        if promote_only:
            if not user:
                print(f"User {email} not found")
                sys.exit(1)
            user.is_admin = True
            db.commit()
            print(f"Promoted {email} to admin")
            return

        if len(sys.argv) < 3:
            print("Password required for new admin user")
            sys.exit(1)

        password = sys.argv[2]
        name = sys.argv[3] if len(sys.argv) > 3 else "Admin"

        if user:
            user.is_admin = True
            user.hashed_password = get_password_hash(password)
            user.is_email_verified = True
            print(f"Updated existing user {email} as admin")
        else:
            user = User(
                email=email,
                name=name,
                hashed_password=get_password_hash(password),
                is_admin=True,
                is_email_verified=True,
                has_paid=True,
            )
            db.add(user)
            print(f"Created admin user {email}")

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    main()
