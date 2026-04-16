require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'models'
require_relative 'validation'
require 'bcrypt'
require 'sinatra/flash'

enable :sessions

include Model
include Validator

# Hash for rate limits. 
rate_limits = {}
next_rate_limit_reset = Time.now.to_i
reset_rate_limit_every_x_seconds = 60

before do
  if next_rate_limit_reset < Time.now.to_i
    rate_limits = {}
    next_rate_limit_reset = Time.now.to_i + reset_rate_limit_every_x_seconds
  end

  rate_limits[request.ip] ||= 0
  if request.path_info.start_with?("/auth") and (request.request_method == "POST" or request.request_method == "post")
    if rate_limits[request.ip] > 10
      return error(429)
    end

    rate_limits[request.ip] += 1
  end

  user_id = session[:user_id]
  @user = user_id == nil ? nil : getUserById(user_id)

  if @user and @user["is_banned"] == 1 and request.path_info != "/logout" and request.path_info != "/banned"
    p "banned"
    p @user
    return redirect("/banned")
  end

  if request.path_info.start_with?("/admin") and (@user == nil or @user["role"] < 1)
    return error(401)
  end
end

# Display landing page
get "/" do
  @categories = getCategories()

  slim(:index)
end

# Display create category form
get "/categories/new" do
  if @user == nil or @user["role"] < 2
    p @user
    error(401)
  end

  slim(:"categories/create")
end

# Post method to create a new category
# 
# @param [String] title, The category title
post "/categories/new" do
  if @user == nil or @user["role"] < 2
    error(401)
  end

  title = params[:title]
  if !validate_category_title(title)
    # return error(400)
    flash[:error] = "Ogiltig rubrik. Den måste vara från 1 till 50 tecken."
    redirect "/categories/new"
  end

  new_category_id = createCategory(title)

  redirect("/categories/#{new_category_id}")
end

# Display a single category
# 
# @param [Integer] :id, the ID of the category
get "/categories/:id" do
  id = params[:id].to_i

  @category = getCategoryById(id)
  if @category == nil
    error(404)
  end

  @threads = getCategoryThreads(id)

  slim(:"categories/view")
end

# Display the update category form
# 
# @param [Integer] :id, the ID of the category
get "/categories/:id/update" do
  if @user == nil or @user["role"] < 2
    error(401)
  end

  id = params[:id].to_i
  @category = getCategoryById(id)
  if @category == nil
    error(404)
  end

  slim(:"categories/update")
end

# Update a single category and redirects to it
# 
# @param [Integer] :id, the ID of the category
# @param [String] title, updated category title
#
# @see Model#updateCategory
post "/categories/:id/update" do
  if @user == nil or @user["role"] < 2
    error(401)
  end

  id = params[:id].to_i
  @category = getCategoryById(id)
  if @category == nil
    error(404)
  end

  title = params[:title]
  if !validate_category_title(title)
    # return error(400)
    flash[:error] = "Ogiltig rubrik. Den måste vara från 1 till 50 tecken."
    redirect "/categories/#{id}/update"
  end

  updateCategory(id, title)

  redirect("/categories/#{id}")
end

# Display the create thread form
# 
# @param [Integer] :id, the ID of the category to create the thread in
get "/categories/:id/new" do
  id = params[:id].to_i

  @category = getCategoryById(id)
  if @category == nil
    error(404)
  end

  slim(:"threads/create")
end

# Create a new thread in the category and redirects to it
# 
# @param [Integer] :id, the ID of the category to create the thread in
# @param [String] title, the thread title
# @param [String] content, the thread content
#
# @see Model#createThread
post "/categories/:id" do
  if @user == nil
    error(401)
  end

  id = params[:id].to_i

  @category = getCategoryById(id)
  if @category == nil
    error(404)
  end

  title = params[:title]
  content = params[:content]
  if !validate_thread_title(title) or !validate_thread_content(content)
    flash[:error] = "Ogiltig rubrik eller beskrivning. Rubriken måste vara minst 1 och max 50 tecken. Beskrivningen får vara max 2000 tecken. "
    redirect "/categories/#{id}/new"
  end

  threadId = createThread(id, title, content, @user["id"])
  
  redirect("/threads/#{threadId}")
end

# Display a single thread
# 
# @param [Integer] :id, the ID of the thread
get "/threads/:id" do
  id = params[:id].to_i
  
  @thread = getThreadById(id)
  if @thread == nil
    error(404)
  end

  @replies = getThreadReplies(id)

  slim(:"threads/view")
end

# Create a post in the thread and redirects to it
# 
# @param [Integer] :id, the ID of the thread to reply to
# @param [String] content, the reply content
#
# @see Model#createReply
post "/threads/:id" do
  if @user == nil
    error(401)
  end

  id = params[:id].to_i

  thread = getThreadById(id)
  if thread == nil
    error(404)
  end

  content = params[:content]
  if !validate_thread_reply(content)
    # return error(400)
    flash[:error] = "Ogiltligt svar. Den får max vara 2000 tecken och inte tom. "
    redirect "/threads/#{id}"
  end

  createReply(id, content, @user["id"])

  redirect("/threads/#{id}")
end

# Display the profile page for a single user
# 
# @param [Integer] :id, the ID of the user to view
get "/users/:id" do 
  id = params[:id]

  if id == "me" 
    if @user == nil
      error(401)
    end

    @profile_user = @user
  else
    id = id.to_i

    @profile_user = getUserById(id)
    if @profile_user == nil
      error(404)
    end
  end

  @followers = getUserFollowersForUser(id)
  @following = getUserFollowingForUser(id)
  @is_following_user = @user != nil ? userFollowsUser(@user["id"], @profile_user["id"]) : false
  @threads = getUserThreads(id, 10, 0)

  @replies_count = countUserReplies(id)

  slim(:"users/view")
end

# Display the followers for the user
# 
# @param [Integer] :id, the ID of the user to list followers for
#
# @see Model#getUserFollowersForUser
get "/users/:id/followers" do 
  id = params[:id].to_i

  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  @followers = getUserFollowersForUser(id)

  slim(:"users/followers")
end

# Display the users the user follows
# 
# @param [Integer] :id, the ID of the user to list following for
#
# @see Model#getUserFollowingForUser
get "/users/:id/following" do 
  id = params[:id].to_i

  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  @following = getUserFollowingForUser(id)

  slim(:"users/following")
end

# If not following the user, it will follow them, else they will unfollow. Redirects to the followed/unfollowed user. 
# 
# @param [Integer] :id, the ID of the user to toggle following
#
# @see Model#followUser
# @see Model#unfollowUser
post "/users/:id/follow" do 
  if @user == nil
    error(401)
  end

  id = params[:id].to_i
  if id == @user["id"]
    error(400) # No error message here because the user will not set this param. 
  end

  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  if userFollowsUser(@user["id"], @profile_user["id"])
    unfollowUser(@user["id"], @profile_user["id"])
  else
    followUser(@user["id"], @profile_user["id"])
  end

  redirect("/users/#{id}")
end

# Display the treads created by a user
# 
# @param [Integer] :id, the ID of the user
# @param [Integer] page, the page of threads to view
#
# @see Model#getUserThreads
get "/users/:id/threads" do
  id = params[:id].to_i

  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  @per_page = 20
  @page = (params[:page] || 0).to_i
  @threads = getUserThreads(id, @per_page, @page)
  @is_last_page = @threads.length < @per_page
  @is_first_page = @page <= 0

  slim(:"users/threads")
end

# Log out the current user by removing the session cookie and redirect to "/auth/login"
post "/logout" do
  session.clear

  redirect("/auth/login")
end

# Display the login form. If the user is already logged in they will redirect to "/"
get "/auth/login" do
  if @user != nil
    redirect("/")
  end

  slim(:"auth/login")
end

# Log in the user. Requires the user to not be currently logged in. The password and username is validated. It redirects to "/" on successful login. 
# 
# @param [String] username, the account username
# @param [String] password, the account password
post "/auth/login" do
  if @user != nil
    redirect("/")
  end
  
  username = params[:username]
  password = params[:password]

  if !validate_username(username) || !validate_password(password)
    flash[:error] = "Användarnamnet eller lösenordet följer inte inte kraven. Användarnamnet måste vara från 4 till 20 tecken och lösenordet från 8 till 50. "
    redirect "/auth/login"
    # error(400)
  end

  login_user = getUserByUsername(username)
  if login_user == nil
    # error(400)
    flash[:error] = "Ogiltigt användarnamn eller lösenord. "
    redirect "/auth/login"
  end

  if BCrypt::Password.new(login_user["pass_dig"]) == password
    session[:user_id] = login_user["id"]
    redirect("/")
  else
    # error(400)
    flash[:error] = "Ogiltigt användarnamn eller lösenord. "
    redirect "/auth/login"
  end
end

# Display the signup form. If the user is already logged in they will redirect to "/". 
get "/auth/signup" do
  if @user != nil
    redirect("/")
  end

  slim(:"auth/signup")
end

# Create the user and log them in. Requires the user to not be currently logged in. The password and username is validated. It redirects to "/" on successful login. 
# 
# @param [String] username, the account username
# @param [String] password, the account password
# @param [String] password_conf, password confirm. Should be same as password
#
# @see Model#getUserByUsername
post "/auth/signup" do
  if @user != nil
    redirect("/")
  end

  username = params[:username]
  password = params[:password]
  password_conf = params[:password_conf]

  if password != password_conf
    # error(400)
    flash[:error] = "Lösenorden matchar inte. "
    redirect "/auth/signup"
  elsif !validate_username(username) || !validate_password(password)
    # error(400)
    flash[:error] = "Användarnamnet eller lösenordet följer inte inte kraven. Användarnamnet måste vara från 4 till 20 tecken och lösenordet från 8 till 50. "
    redirect "/auth/signup"
  end

  existing_user = getUserByUsername(username)
  if existing_user != nil
    # error(400)
    flash[:error] = "Användarnamnet är redan taget. "
    redirect "/auth/signup"
  end

  password_digest = BCrypt::Password.create(password)

  new_user_id = createUser(username, password_digest)
  session[:user_id] = new_user_id

  redirect "/"
end

# Admin route to remove a single user. Requires admin privileges. Removes all associated threads, replies and categories. 
# 
# @param [Integer] :id, the user ID of the user to remove
#
# @see Model#deleteUser
post "/admin/users/:id/delete" do
  id = params[:id]
  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  deleteUser(id)

  redirect("/")
end

# Admin route to ban a single user. Requires admin privileges. Banned users cannot interact with the site, but their threads, replies and categories remain. 
# 
# @param [Integer] :id, the user ID of the user to ban
# @param [Integer] status, status of the ban. 1 to ban and 0 to unban
#
# @see Model#banUser
post "/admin/users/:id/ban" do
  id = params[:id]
  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  status = params[:status].to_i
  if status != 0 and status != 1
    error(400)
  end

  banUser(id, status)

  redirect("/users/#{id}")
end

# Display the landing page for banned users
get "/banned" do
  if @user and @user["is_banned"] == 1
    return slim(:banned)
  end

  redirect("/")
end

# Delete a single thread. Requires the user to be either the thread owner or an admin. All associated replies will be deleted. Redirects to the parent category of the deleted thread. 
#
# @param [Integer] :thread_id, the ID of the thread to remove
#
# @see Model#deleteThread
post "/threads/:thread_id/delete" do
  thread_id = params[:thread_id]
  thread = getThreadById(thread_id)
  if thread == nil
    error(404)
  end

  if @user == nil or (@user["id"] != thread["owner_id"] and @user["role"] == 0)
    error(401)
  end

  deleteThread(thread_id)

  redirect("/categories/#{thread["category_id"]}")
end

# Delete a single thread reply. Requires the user to be either the reply owner or an admin. Redirects to the thread after deletion. 
#
# @param [Integer] :thread_id, the ID of the thread where the reply is
# @param [Integer] :reply_id, the ID of the reply to remove
#
# @see Model#deleteReply
post "/threads/:thread_id/replies/:reply_id/delete" do
  thread_id = params[:thread_id]
  thread = getThreadById(thread_id)
  if thread == nil
    error(404)
  end

  reply_id = params[:reply_id]
  reply = getThreadReplyById(reply_id)
  if reply == nil
    error(404)
  end

  if @user == nil or (@user["id"] != reply["owner_id"] and @user["role"] == 0)
    error(401)
  end

  deleteReply(reply_id)

  redirect("/threads/#{thread["id"]}")
end

# Display the account settings page
get "/account" do
  if @user == nil
    redirect("/auth/login")
  end

  slim(:"account/view")
end

# Update the account settings
# 
# @param [String] username, new username
#
# @see Model#updateUser
post "/account" do
  if @user == nil
    redirect("/auth/login")
  end

  username = params[:username]
  if !validate_username(username)
    # error(400)
    flash[:error] = "Användarnamnet måste vara från 4 till 20 tecken. "
    redirect "/account"
  end

  existing_user = getUserByUsername(username)
  if existing_user
    # error(400)
    flash[:error] = "Användarnamnet är upptaget. "
    redirect "/account"
  end

  updateUser(@user["id"], username)

  redirect("/account")
end

# Update the account password. On success redirects to "/account"
#
# @param [String] :existing_pass, current password
# @param [String] :new_pass, new password
# @param [String] :new_pass_confirm, repeat of :new_pass
#
# @see Model#updateUserPass
post "/account/updatePassword" do
  if @user == nil
    redirect("/auth/login")
  end

  existing_pass = params[:existing_pass]
  new_pass = params[:new_pass]
  new_pass_confirm = params[:new_pass_confirm]
  if new_pass != new_pass_confirm
    p "Pass not matching"
    # error(400)
    flash[:error] = "Lösenorden matchar inte. "
    redirect "/account"
  elsif !validate_password(new_pass)
    p "invalid pass"
    # error(400)
    flash[:error] = "Ogilltligt lösenord. Det måste vara minst 8 tecken och max 50. "
    redirect "/account"
  end

  if BCrypt::Password.new(@user["pass_dig"]) == existing_pass
    updateUserPass(@user["id"], BCrypt::Password.create(new_pass))

    redirect("/account")
  else
    # error(400)
    flash[:error] = "Fel lösenord. "
    redirect "/account"
  end
end