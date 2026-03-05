require 'sqlite3'
require 'BCrypt'

db = SQLite3::Database.new("databas.db")


def seed!(db)
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS user')
  db.execute('DROP TABLE IF EXISTS category')
  db.execute('DROP TABLE IF EXISTS thread')
  db.execute('DROP TABLE IF EXISTS reply')
  db.execute('DROP TABLE IF EXISTS user_follow_user')
end

def create_tables(db)
  db.execute('CREATE TABLE user (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL COLLATE NOCASE,
              pass_dig TEXT NOT NULL,
              role INTEGER NOT NULL DEFAULT 0)')
  db.execute('CREATE TABLE category (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL)')
  db.execute('CREATE TABLE thread (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              owner_id INTEGER NOT NULL,
              created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY(category_id) REFERENCES category(id) ON DELETE CASCADE,
              FOREIGN KEY(owner_id) REFERENCES user(id) ON DELETE CASCADE)')
  db.execute('CREATE TABLE reply (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              thread_id INTEGER NOT NULL,
              content TEXT NOT NULL,
              owner_id INTEGER NOT NULL,
              created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY(thread_id) REFERENCES thread(id) ON DELETE CASCADE,
              FOREIGN KEY(owner_id) REFERENCES user(id) ON DELETE CASCADE)')
  db.execute('CREATE TABLE user_follow_user (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              follower_id INTEGER NOT NULL,
              following_id INTEGER NOT NULL,
              created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY(follower_id) REFERENCES user(id) ON DELETE CASCADE,
              FOREIGN KEY(following_id) REFERENCES user(id) ON DELETE CASCADE)')
end

def populate_tables(db)
  db.execute("INSERT INTO user (username, pass_dig, role) VALUES (?, ?, ?)", ["skibidi", BCrypt::Password.create("toilet123"), 3])
  db.execute("INSERT INTO user (username, pass_dig) VALUES (?, ?)", ["fortnite", BCrypt::Password.create("roblox123")])

  category_id_1 = db.execute("INSERT INTO category (name) VALUES (?) RETURNING id", ["Roblox"])[0][0]
  category_id_2 = db.execute("INSERT INTO category (name) VALUES (?) RETURNING id", ["Fortnite"])[0][0]

  roblox_thread_id_1 = db.execute("INSERT INTO thread (category_id, title, content, owner_id) VALUES (?, ?, ?, ?) RETURNING id", [category_id_1, "Varför är Roblox bättre än Fortnite?", "Hjälp mig!", 1])[0][0]
  db.execute("INSERT INTO reply (thread_id, content, owner_id) VALUES (?, ?, ?)", [roblox_thread_id_1, "Har du någonsin testat Fortnite?", 2])
  db.execute("INSERT INTO reply (thread_id, content, owner_id) VALUES (?, ?, ?)", [roblox_thread_id_1, "Nej, vadå?", 1])
  db.execute("INSERT INTO reply (thread_id, content, owner_id) VALUES (?, ?, ?)", [roblox_thread_id_1, "Om du hade testat att spela Fortnite någon gång hade du märkt att det är bäst, kan man ens använda emotes i Roblox?", 2])
  db.execute("INSERT INTO reply (thread_id, content, owner_id) VALUES (?, ?, ?)", [roblox_thread_id_1, "Ja, mycket bättre emotes. Fortnite är sämst!", 1])

  fortnite_thread_id_1 = db.execute("INSERT INTO thread (category_id, title, content, owner_id) VALUES (?, ?, ?, ?) RETURNING id", [category_id_2, "Roblox är bättre!", "Det är sant!", 1])[0][0]
  db.execute("INSERT INTO reply (thread_id, content, owner_id) VALUES (?, ?, ?)", [fortnite_thread_id_1, "Jag kanske borde testa Roblox", 2])
end


seed!(db)





