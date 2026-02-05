require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

before do
  user_id = session[:user_id]
  if user_id == nil
      @user = nil
      return
  end

  db = connectToDb()
  user = db.execute("SELECT id, username FROM users WHERE id=?", [user_id])
  if user.empty?
      @user = nil
      return
  end

  @user = user[0]
end

def connectToDb()
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true

  return db
end

get "/" do
  db = connectToDb()
  @categories = db.execute("SELECT id, name FROM category")

  slim(:index)
end

get "/categories/:id" do
  id = params[:id].to_i
  db = connectToDb()

  categories = db.execute("SELECT * FROM category WHERE id = ?", [id])
  if categories.empty?
    error(404)
  end

  @category = categories.first
  @threads = db.execute("SELECT * FROM thread WHERE category_id = ? ORDER BY created DESC", [id])

  slim(:"categories/view")
end

get "/threads/:id" do
  id = params[:id].to_i
  db = connectToDb()

  threads = db.execute("SELECT * FROM thread WHERE id = ?", [id])
  if threads.empty?
    error(404)
  end

  @thread = threads.first
  @replies = db.execute("SELECT * FROM reply where thread_id = ? ORDER BY created, id ASC", [id])

  slim(:"threads/view")
end

post "/threads/:id" do
  id = params[:id].to_i
  db = connectToDb()

  threads = db.execute("SELECT * FROM thread WHERE id = ?", [id])
  if threads.empty?
    error(404)
  end

  content = params[:content]
  if content.empty?
    error(400)
  end

  db.execute("INSERT INTO reply (thread_id, content, owner_id) VALUES (?, ?, ?)", [id, content, 1])

  redirect("/threads/#{id}")
end