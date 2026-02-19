require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'models'

before do
  user_id = session[:user_id]
  if user_id == nil
      @user = nil
      return
  end

  @user = getUserById(user_id)
end

get "/" do
  @categories = getCategories()

  slim(:index)
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
  id = params[:id].to_i

  @category = getCategoryById(id)
  if @category == nil
    error(404)
  end

  title = params[:title]
  content = params[:content]
  if title.empty? or content.empty?
    error(400)
  end

  threadId = createThread(id, title, content, 1)
  
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
  id = params[:id].to_i

  threads = getThreadById(id)
  if threads.empty?
    error(404)
  end

  content = params[:content]
  if content.empty?
    error(400)
  end

  createReply(id, content, 1)

  redirect("/threads/#{id}")
end

get "/users/:id" do 
  id = params[:id].to_i

  @user = getUserById(id)
  if @user == nil
    error(404)
  end

  slim(:"users/view")
end