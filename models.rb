def connectToDb()
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true

  return db
end

def getUserById(id)
  db = connectToDb()
  user = db.execute("SELECT id, username FROM users WHERE id=?", [user_id])

  return user.first
end

def getCategories()
  db = connectToDb()
  categories = db.execute("SELECT id, name FROM category")

  return categories
end

def getCategoryById(id)
  db = connectToDb()
  categories = db.execute("SELECT * FROM category WHERE id = ?", [id])

  return categories.first
end

def getCategoryThreads(categoryId)
  db = connectToDb()
  threads = db.execute("SELECT * FROM thread WHERE category_id = ? ORDER BY created DESC", [categoryId])

  return threads
end

def getThreadById(id)
  db = connectToDb()
  threads = db.execute("SELECT * FROM thread WHERE id = ?", [id])

  return threads.first
end

def createThread(categoryId, title, content, ownerId)
  db = connectToDb()
  ids = db.execute("INSERT INTO thread (category_id, title, content, owner_id) VALUES (?, ?, ?, ?) RETURNING id", [categoryId, title, content, ownerId])
  
  return ids.first["id"]
end

def getThreadReplies(threadId)
  db = connectToDb()
  replies = db.execute("SELECT * FROM reply WHERE thread_id = ? ORDER BY created, id ASC", [threadId])

  return replies
end

def createReply(threadId, content, ownerId)
  db = connectToDb()
  db.execute("INSERT INTO reply (thread_id, content, owner_id) VALUES (?, ?, ?)", [threadId, content, ownerId])
end

def getUserById(id)
  db = connectToDb()
  users = db.execute("SELECT * FROM user WHERE id = ?", [id])

  return users.first
end