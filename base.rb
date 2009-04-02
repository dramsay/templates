run "rm public/index.html"
run "rm public/images/rails.png"
run "rm README"
run "cp config/database.yml config/database.yml.example"
run "rm public/favicon.ico"
run "rm public/robots.txt"
 
file '.gitignore', <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END
 
git :init
git :add => "."
git :commit => '-m "Initial commit."'

plugin 'asset_packager', :git => 'script/plugin install git://github.com/sbecker/asset_packager.git'
plugin 'hoptoad_notifier', :git => 'git://github.com/thoughtbot/hoptoad_notifier.git'

hoptoad_key = ask("What is your Hoptoad API key?")

file 'config/initializers/hoptoad.rb', <<-CODE
HoptoadNotifier.configure do |config|
  config.api_key = "#{hoptoad_key}"
end
CODE

gem 'authlogic'
gem 'cucumber'
gem 'rspec', :lib => false
gem 'rspec-rails', :lib => false
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'carlosbrando-remarkable', :lib => 'remarkable', :source => 'http://gems.github.com'
gem 'webrat'
gem 'mislav-will_paginate', :version => '~> 2.2.3',
  :lib => 'will_paginate', :source => 'http://gems.github.com'

if yes?("Run rake gems:install? (yes/no)")
  rake("gems:install", :sudo => true)
end

if yes?("Unpack gems? (yes/no)")
  rake("gems:unpack")
end

if yes?("Freeze Rails? (yes/no)")
  freeze!
end

run "rm -f public/javascripts/*"
run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.2.6.min.js > public/javascripts/jquery.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

generate('rspec')
generate('cucumber')
generate('session', 'user_session')
generate('rspec_scaffold', 'user login:string crypted_password:string password_salt:string persistence_token:string login_count:integer last_request_at:datetime last_login_at:datetime current_login_at:datetime last_login_ip:string current_login_ip:string')

file 'app/models/user.rb', <<-CODE
class User < ActiveRecord::Base
  acts_as_authentic
end
CODE

file 'app/controllers/user_sessions_controller.rb', <<-CODE
class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end
CODE

file 'app/controllers/users_controller.rb', <<-CODE
class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end

  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end
end
CODE

file 'app/controllers/application_controller.rb', <<-CODE
class ApplicationController < ActionController::Base
  filter_parameter_logging :password, :password_confirmation
  helper_method :current_user_session, :current_user

  private
   
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  
end
CODE

route 'map.resource :user_session'
route 'map.root :controller => "user_sessions", :action => "new"'
route 'map.resource :account, :controller => "users"'
route 'map.resources :users'

git :add => "."
git :commit => '-m "Adding templates, plugins and gems"'

if yes?("Create and migrate databases now? (yes/no)")
  rake("db:create:all")
  rake("db:migrate")
end

puts "TO-DO checklist:"
puts "* Create views for Authlogic - see http://github.com/binarylogic/authlogic_example/tree/master/app/views for examples"
puts "* Test your Hoptoad installation with: rake hoptoad:test"
puts "* Generate your asset_packager config with: rake asset:packager:create_yml"
