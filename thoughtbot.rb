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

plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'
plugin 'hoptoad_notifier', :git => 'git://github.com/thoughtbot/hoptoad_notifier.git'

hoptoad_key = ask("What is your Hoptoad API key?")

file 'config/initializers/hoptoad.rb', <<-CODE
HoptoadNotifier.configure do |config|
  config.api_key = "#{hoptoad_key}"
end
CODE

gem 'thoughtbot-factory_girl', :version => '~> 1.2.1', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
gem 'thoughtbot-clearance', :version => '~> 0.6.6', :lib => 'clearance', :source => 'http://gems.github.com'
gem 'webrat', :version => '~> 0.4.4'
gem 'cucumber', :version => '~> 0.3.0'
gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate', :source => 'http://gems.github.com'

if yes?("Run rake gems:install? (yes/no)")
  rake("gems:install", :sudo => true)
end

if yes?("Unpack gems? (yes/no)")
  rake("gems:unpack")
end  

if yes?("Freeze Rails? (yes/no)")
  rake("rails:freeze:edge RELEASE=2.3.2")
end  

generate('cucumber')

run "git rm public/javascripts/controls.js public/javascripts/dragdrop.js public/javascripts/effects.js public/javascripts/prototype.js"
run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > public/javascripts/jquery.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

file 'public/javascripts/application.js', <<-CODE
  jQuery.ajaxSetup({ 
      'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
  });
CODE

route 'map.root :controller => "home", :action => "index"'

git :add => "."
git :commit => '-m "Adding templates, plugins and gems"'


puts "#" * 30
puts "TO-DO checklist:"
puts "\t* Set the HOST value config/environments/production.rb"
puts "\t* Set the DO_NOT_REPLY value in config/environment.rb" 
# NOTE: I tried "generate('clearance')" and "generate('clearance_features') in the template but
# the generators didn't work
puts "\t* Run: script/generate clearance"
puts "\t* Run: script/generate clearance_features"
puts "\t* Test your Hoptoad installation with: rake hoptoad:test"
puts "\t* Generate your asset_packager config with: rake asset:packager:create_yml"
puts "#" * 30
