require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'models'
require_relative 'validation'
require 'bcrypt'

enable :sessions

before do
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

get "/" do
  @categories = getCategories()

  slim(:index)
end

get "/categories/new" do
  if @user == nil or @user["role"] < 2
    p @user
    error(401)
  end

  slim(:"categories/create")
end

post "/categories/new" do
  if @user == nil or @user["role"] < 2
    error(401)
  end

  title = params[:title]
  if !validate_category_title(title)
    return error(400)
  end

  new_category_id = createCategory(title)

  redirect("/categories/#{new_category_id}")
end

get "/categories/:id" do
  id = params[:id].to_i

  @category = getCategoryById(id)
  if @category == nil
    error(404)
  end

  @threads = getCategoryThreads(id)

  slim(:"categories/view")
end

get "/categories/:id/new" do
  id = params[:id].to_i

  @category = getCategoryById(id)
  if @category == nil
    error(404)
  end

  slim(:"threads/create")
end

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
    return error(400)
  end

  threadId = createThread(id, title, content, @user["id"])
  
  redirect("/threads/#{threadId}")
end

get "/threads/:id" do
  id = params[:id].to_i
  
  @thread = getThreadById(id)
  if @thread == nil
    error(404)
  end

  @replies = getThreadReplies(id)

  slim(:"threads/view")
end

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
    return error(400)
  end

  createReply(id, content, @user["id"])

  redirect("/threads/#{id}")
end

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

get "/users/:id/followers" do 
  id = params[:id].to_i

  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  @followers = getUserFollowersForUser(id)

  slim(:"users/followers")
end

get "/users/:id/following" do 
  id = params[:id].to_i

  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  @following = getUserFollowingForUser(id)
  p @following

  slim(:"users/following")
end

post "/users/:id/follow" do 
  if @user == nil
    error(401)
  end

  id = params[:id].to_i
  if id == @user["id"]
    error(400)
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

post "/logout" do
  session.clear

  redirect("/auth/login")
end

get "/auth/login" do
  if @user != nil
    redirect("/")
  end

  slim(:"auth/login")
end

post "/auth/login" do
  if @user != nil
    redirect("/")
  end

  username = params[:username]
  password = params[:password]

  if !validate_username(username) || !validate_password(password)
    p  validate_username(username)
    p validate_password(password)
    error(400)
  end

  login_user = getUserByUsername(username)
  if login_user == nil
    error(400)
  end

  if BCrypt::Password.new(login_user["pass_dig"]) == password
    session[:user_id] = login_user["id"]
    redirect("/")
  else
    error(400)
  end
end

get "/auth/signup" do
  if @user != nil
    redirect("/")
  end

  slim(:"auth/signup")
end

post "/auth/signup" do
  if @user != nil
    redirect("/")
  end

  username = params[:username]
  password = params[:password]
  password_conf = params[:password_conf]

  if password != password_conf
    p "missmatch"
    error(400)
  elsif !validate_username(username) || !validate_password(password)
    p validate_username(username)
    p validate_password(password)
    error(400)
  end

  existing_user = getUserByUsername(username)
  if existing_user != nil
    error(400)
  end

  password_digest = BCrypt::Password.create(password)

  new_user_id = createUser(username, password_digest)
  session[:user_id] = new_user_id

  redirect "/"
end

post "/admin/users/:id/delete" do
  id = params[:id]
  @profile_user = getUserById(id)
  if @profile_user == nil
    error(404)
  end

  deleteUser(id)

  redirect("/")
end

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

get "/banned" do
  p @user
  if @user and @user["is_banned"] == 1
    return slim(:banned)
  end

  p @user

  redirect("/")
end

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