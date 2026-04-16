module Model
  # Create a connection to the database
  # 
  # @return [DataBase] the database connection
  def connectToDb()
    db = SQLite3::Database.new("db/databas.db")
    db.execute("PRAGMA foreign_keys = ON;")
    db.results_as_hash = true

    return db
  end

  # Query a single user
  # 
  # @param [Integer] id, ID of the user to query
  #
  # @return [Hash] the user if it exists
  # @return [nil] if not found
  def getUserById(id)
    db = connectToDb()
    user = db.execute("SELECT * FROM users WHERE id=?", [user_id])

    return user.first
  end

  # Get all categories
  # 
  # @return [Array] all the categories
  def getCategories()
    db = connectToDb()
    categories = db.execute("SELECT id, name FROM category")

    return categories
  end

  # Query a single category
  # 
  # @param [integer] id, ID of the category to query
  #
  # @return [Hash] the category if it exists
  # @return [nil] if not found
  def getCategoryById(id)
    db = connectToDb()
    categories = db.execute("SELECT * FROM category WHERE id = ?", [id])

    return categories.first
  end

  # Query the threads in a category
  # 
  # @param [Integer] id, ID of the category to query threads for
  #
  # @return [Array] all the threads
  def getCategoryThreads(categoryId)
    db = connectToDb()
    threads = db.execute("SELECT * FROM thread WHERE category_id = ? ORDER BY created DESC", [categoryId])

    return threads
  end

  # Query a single thread with owner information
  # 
  # @param [Integer] id, ID of the thread to query
  #
  # @return [Hash] the thread details if it exists
  # @return [nil] if not found
  def getThreadById(id)
    db = connectToDb()
    threads = db.execute("SELECT thread.id, user.username, thread.category_id, thread.title, thread.content, thread.owner_id, thread.created FROM thread LEFT JOIN user ON thread.owner_id = user.id WHERE thread.id = ?", [id])

    return threads.first
  end

  # Create a new thread
  # 
  # @param [Integer] categoryId, ID of the category
  # @param [String] title, the thread title
  # @param [String] content, the thread content
  # @param [Integer] ownerId, ID of the user creating the thread
  #
  # @return [Integer] the ID of the created thread
  def createThread(categoryId, title, content, ownerId)
    db = connectToDb()
    ids = db.execute("INSERT INTO thread (category_id, title, content, owner_id) VALUES (?, ?, ?, ?) RETURNING id", [categoryId, title, content, ownerId])
    
    return ids.first["id"]
  end

  # Get all replies for a specific thread
  # 
  # @param [Integer] threadId, ID of the thread
  #
  # @return [Array] list of replies with author usernames
  def getThreadReplies(threadId)
    db = connectToDb()
    replies = db.execute("SELECT reply.id, reply.thread_id, reply.content, reply.owner_id, reply.created, user.username FROM reply LEFT JOIN user ON reply.owner_id = user.id WHERE reply.thread_id = ? ORDER BY reply.created, reply.id ASC", [threadId])
    p replies

    return replies
  end

  # Create a new reply
  # 
  # @param [Integer] threadId, ID of the thread
  # @param [String] content, the reply content
  # @param [Integer] ownerId, ID of the user replying
  def createReply(threadId, content, ownerId)
    db = connectToDb()
    db.execute("INSERT INTO reply (thread_id, content, owner_id) VALUES (?, ?, ?)", [threadId, content, ownerId])
  end

  # Get followers for a user
  # 
  # @param [Integer] id, ID of the user being followed
  #
  # @return [Array] list of followers
  def getUserById(id)
    db = connectToDb()
    users = db.execute("SELECT * FROM user WHERE id = ?", [id])

    return users.first
  end

  # Get followers for a user
  # 
  # @param [Integer] id, ID of the user being followed
  #
  # @return [Array] list of followers
  def getUserFollowersForUser(id) 
    db = connectToDb()
    followers = db.execute("SELECT * FROM user_follow_user INNER JOIN user ON user_follow_user.follower_id = user.id WHERE user_follow_user.following_id = ?", [id])

    return followers
  end

  # Get users that a user is following
  # 
  # @param [Integer] id, ID of the follower
  #
  # @return [Array] list of followed users
  def getUserFollowingForUser(id) 
    db = connectToDb()
    followers = db.execute("SELECT * FROM user_follow_user INNER JOIN user ON user_follow_user.following_id = user.id WHERE user_follow_user.follower_id = ?", [id])
    
    return followers
  end

  # Check if a user follows another
  # 
  # @param [Integer] follower, ID of the follower
  # @param [Integer] following, ID of the followed user
  #
  # @return [Boolean] true if relationship exists
  def userFollowsUser(follower, following)
    db = connectToDb()
    connection = db.execute("SELECT * from user_follow_user WHERE follower_id = ? AND following_id = ?", [follower, following])

    return !connection.empty?
  end

  # Create a follow relationship
  # 
  # @param [Integer] follower, ID of the follower
  # @param [Integer] following, ID of the user to follow
  def followUser(follower, following) 
    db = connectToDb()
    db.execute("INSERT INTO user_follow_user (follower_id, following_id) VALUES (?, ?)", [follower, following])
  end

  # Remove a follow relationship
  # 
  # @param [Integer] follower, ID of the follower
  # @param [Integer] following, ID of the followed user
  def unfollowUser(follower, following) 
    db = connectToDb()
    db.execute("DELETE FROM user_follow_user where follower_id = ? AND following_id = ?", [follower, following])
  end

  # Get paginated threads for a specific user
  # 
  # @param [Integer] user_id, ID of the user
  # @param [Integer] limit, number of results per page
  # @param [Integer] page, current page index
  #
  # @return [Array] list of threads
  def getUserThreads(user_id, limit, page)  
    db = connectToDb()  
    threads = db.execute("SELECT * FROM thread WHERE owner_id = ? ORDER BY created DESC LIMIT ? OFFSET ?", [user_id, limit, page * limit])

    return threads
  end

  # Count total replies by a user
  # 
  # @param [Integer] user_id, ID of the user
  #
  # @return [Integer] total count of replies
  def countUserReplies(user_id) 
    db = connectToDb()
    db.results_as_hash = false

    res = db.execute("SELECT COUNT(*) FROM reply WHERE owner_id = ?", [user_id])

    return res.first[0]
  end

  # Query a single user by username
  # 
  # @param [String] username
  #
  # @return [Hash] the user if it exists
  def getUserByUsername(username)
    db = connectToDb()
    users = db.execute("SELECT * FROM user WHERE username = ?", [username])

    return users.first
  end

  # Register a new user
  # 
  # @param [String] username
  # @param [String] password_digest, the hashed password
  #
  # @return [Integer] the ID of the new user
  def createUser(username, password_digest)
    db = connectToDb()
    users = db.execute("INSERT INTO user (username, pass_dig) VALUES (?, ?) RETURNING id", [username, password_digest])

    return users.first["id"]
  end

  # Create a new category
  # 
  # @param [String] name
  #
  # @return [Integer] the ID of the new category
  def createCategory(name)
    db = connectToDb()
    categories = db.execute("INSERT INTO category (name) VALUES (?) RETURNING id", [name])

    return categories.first["id"]
  end

  # Update a category name
  # 
  # @param [Integer] id
  # @param [String] name
  def updateCategory(id, name)
    db = connectToDb()
    categories = db.execute("UPDATE category SET name = ? WHERE id = ?", [name, id])
  end

  # Delete a user
  # 
  # @param [Integer] id
  def deleteUser(id)
    db = connectToDb()
    db.execute("DELETE FROM user WHERE id = ?", [id])
  end

  # Update user profile
  # 
  # @param [Integer] id
  # @param [String] username
  def updateUser(id, username) 
    db = connectToDb()
    db.execute("UPDATE user SET username = ? WHERE id = ?", [username, id])
  end

  # Update user password
  # 
  # @param [Integer] id
  # @param [String] new_pass_dig, the new hashed password
  def updateUserPass(id, new_pass_dig)
    db = connectToDb()
    db.execute("UPDATE user SET pass_dig = ? WHERE id = ?", [new_pass_dig, id])
  end

  # Ban or unban a user
  # 
  # @param [Integer] id
  # @param [Integer] status, 1 for banned, 0 for active
  def banUser(id, status) 
    db = connectToDb()
    db.execute("UPDATE user SET is_banned = ? WHERE id = ?", [status, id])
  end

  # Delete a thread
  # 
  # @param [Integer] id
  def deleteThread(id)
    db = connectToDb()
    db.execute("DELETE FROM thread WHERE id = ?", [id])
  end

  # Query a single reply
  # 
  # @param [Integer] id
  #
  # @return [Hash] the reply if it exists
  def getThreadReplyById(id)
    db = connectToDb()
    replies = db.execute("SELECT * FROM reply WHERE id = ?", [id])

    return replies.first
  end

  # Delete a reply
  # 
  # @param [Integer] id
  def deleteReply(id)
    db = connectToDb()
    db.execute("DELETE FROM reply WHERE id = ?", [id])
  end
end