def connectToDb()
  db = SQLite3::Database.new("db/databas.db")
  db.execute("PRAGMA foreign_keys = ON;")
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

def getUserFollowersForUser(id) 
  db = connectToDb()
  followers = db.execute("SELECT * FROM user_follow_user INNER JOIN user ON user_follow_user.follower_id = user.id WHERE user_follow_user.following_id = ?", [id])

  return followers
end

def getUserFollowingForUser(id) 
  db = connectToDb()
  followers = db.execute("SELECT * FROM user_follow_user INNER JOIN user ON user_follow_user.following_id = user.id WHERE user_follow_user.follower_id = ?", [id])
  
  return followers
end

def userFollowsUser(follower, following)
  db = connectToDb()
  connection = db.execute("SELECT * from user_follow_user WHERE follower_id = ? AND following_id = ?", [follower, following])

  return !connection.empty?
end

def followUser(follower, following) 
  db = connectToDb()
  db.execute("INSERT INTO user_follow_user (follower_id, following_id) VALUES (?, ?)", [follower, following])
end

def unfollowUser(follower, following) 
  db = connectToDb()
  db.execute("DELETE FROM user_follow_user where follower_id = ? AND following_id = ?", [follower, following])
end

def getUserThreads(user_id, limit, page)  
  db = connectToDb()  
  threads = db.execute("SELECT * FROM thread WHERE owner_id = ? ORDER BY created DESC LIMIT ? OFFSET ?", [user_id, limit, page * limit])

  return threads
end

def countUserReplies(user_id) 
  db = connectToDb()
  db.results_as_hash = false

  res = db.execute("SELECT COUNT(*) FROM reply WHERE owner_id = ?", [user_id])

  return res.first[0]
end

def getUserByUsername(username)
  db = connectToDb()
  users = db.execute("SELECT * FROM user WHERE username = ?", [username])

  return users.first
end

def createUser(username, password_digest)
  db = connectToDb()
  users = db.execute("INSERT INTO user (username, pass_dig) VALUES (?, ?) RETURNING id", [username, password_digest])

  return users.first["id"]
end

def createCategory(name)
  db = connectToDb()
  categories = db.execute("INSERT INTO category (name) VALUES (?) RETURNING id", [name])

  return categories.first["id"]
end

def deleteUser(id)
  db = connectToDb()
  db.execute("DELETE FROM user WHERE id = ?", [id])
end

def banUser(id, status) 
  db = connectToDb()
  db.execute("UPDATE user SET is_banned = ? WHERE id = ?", [status, id])
end

def deleteThread(id)
  db = connectToDb()
  db.execute("DELETE FROM thread WHERE id = ?", [id])
end

def getThreadReplyById(id)
  db = connectToDb()
  replies = db.execute("SELECT * FROM reply WHERE id = ?", [id])

  return replies.first
end

def deleteReply(id)
  db = connectToDb()
  db.execute("DELETE FROM reply WHERE id = ?", [id])
end