# insecure-app

This app is intended to have an intentional security flaw that allows you to run commands inside the container.

## Usage

Run example: 
```
cd workshop/insecure-app
docker build -t lastcoolnameleft/insecure-app:latest .
docker run -p 8080:8080 -e AUTH_USERNAME=foo -e AUTH_PASSWORD=bar lastcoolnameleft/insecure-app:latest
```

Once running, it will respond to the following paths:

| Path | Description |
| --- | --- |
| / | Nothing happens |
| /crash | Simulates crashing the app which will display each of the environment variables |
| /admin | Provides an "admin panel" which can be used to run commands inside the container. Uses Basic Auth to protect the admin panel.  Creds can be gathered from the env vars from /crash |


## Seed the SQLite database

```
sqlite3 insecure-app/tutorial.db

-- Create the users table
CREATE TABLE users (
    username TEXT PRIMARY KEY,
    password TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT NOT NULL UNIQUE
);

-- Insert sample data into the users table
INSERT INTO users (username, password, email, phone) VALUES ('user1', 'password1', 'user1@example.com', '111-111-1111');
INSERT INTO users (username, password, email, phone) VALUES ('user2', 'password2', 'user2@example.com', '222-222-2222');
INSERT INTO users (username, password, email, phone) VALUES ('user3', 'password3', 'user3@example.com', '333-333-3333');
INSERT INTO users (username, password, email, phone) VALUES ('user4', 'password4', 'user4@example.com', '444-444-4444');
INSERT INTO users (username, password, email, phone) VALUES ('user5', 'password5', 'user5@example.com', '555-555-5555');
INSERT INTO users (username, password, email, phone) VALUES ('user6', 'password6', 'user6@example.com', '666-666-6666');
INSERT INTO users (username, password, email, phone) VALUES ('user7', 'password7', 'user7@example.com', '777-777-7777');
INSERT INTO users (username, password, email, phone) VALUES ('user8', 'password8', 'user8@example.com', '888-888-8888');
INSERT INTO users (username, password, email, phone) VALUES ('user9', 'password9', 'user9@example.com', '999-999-9999');
INSERT INTO users (username, password, email, phone) VALUES ('user10', 'password10', 'user10@example.com', '000-000-0000');
```
