require "fileutils"
require "shellwords"

# # Copied from: https://github.com/mattbrictson/rails-template
# # Add this template directory to source_paths so that Thor actions like
# # copy_file and template resolve against our source files. If this file was
# # invoked remotely via HTTP, that means the files are not present locally.
# # In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("quickstart-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/jameslutley/rails-quickstart.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{quickstart/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def add_gems
  gem 'administrate', '~> 0.11.0'
  gem 'devise', '~> 4.5'
  gem 'devise_masquerade', '~> 0.6.5'
  gem 'foreman', '~> 0.85.0'
  gem 'friendly_id', '~> 5.2', '>= 5.2.5'
  gem 'gravatar_image_tag', '~> 1.2'
  gem 'local_time', '~> 2.1'
  gem 'mini_magick', '~> 4.9', '>= 4.9.2'
  gem 'name_of_person', '~> 1.1'
  # gem 'omniauth-facebook', '~> 5.0'
  gem 'omniauth-google-oauth2', '~> 0.6.0'
  gem 'omniauth-twitter', '~> 1.4'
  gem 'sidekiq', '~> 5.2', '>= 5.2.5'
  gem 'sitemap_generator', '~> 6.0', '>= 6.0.2'
  gem 'tailwindcss', '~> 0.2.0'
  gem 'whenever', require: false

  gem_group :development do
    gem 'bullet', '~> 5.9'
    gem 'better_errors', '~> 2.5'
    gem 'binding_of_caller', '~> 0.8.0'
  end

  gem_group :test do
    gem 'rails-controller-testing', '~> 1.0', '>= 1.0.4'
    gem 'minitest', '~> 5.11', '>= 5.11.3'
    gem 'minitest-reporters', '~> 1.3', '>= 1.3.5'
    gem 'guard', '~> 2.15'
    gem 'guard-minitest', '~> 2.4', '>= 2.4.6'
    gem 'terminal-notifier-guard', '~> 1.7'
  end
end

def set_application_name
  # Add Application Name to Config
  environment "config.application_name = Rails.application.class.parent_name"

  # Announce the user where he can change the application name in the future.
  puts "You can change application name inside: ./config/application.rb"
end

def add_minitest
  # Install Minitest
  generate "minitest:install"

  # Configure Minitest and Guard
  guardfile = <<-EOL
    guard :minitest, :all_on_start => false do
      watch(%r{^test/(.*)_test\.rb$})
      watch(%r{^lib/(.+)\.rb$})         { |m| "test/lib/\#{m[1]}_test.rb" }
      watch(%r{^test/test_helper\.rb$}) { 'test' }

      watch(%r{^app/(models|mailers|helpers)/(.+)\.rb$}) { |m|
        "test/\#{m[1]}/\#{m[2]}_test.rb"
      }
      watch(%r{^app/controllers/api/(.+)_controller\.rb$}) { |m| "test/requests/\#{m[1]}_test.rb" }
    end
  EOL

  # Create Guardfile
  create_file "Guardfile", guardfile
end

# def add_root
#   if yes? 'Do you wish to generate a root controller? (y/n)'
#     name = ask('What do you want to call it?').to_s.underscore
#     generate :controller, "#{name} show"
#     route "root to: '#{name}\#show'"
#     route "resource :#{name}, controller: :#{name}, only: [:show]"
#   end
# end

def add_users
  # Install Devise
  generate "devise:install"

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'
  route "root to: 'home#index'"

  # Create Devise views
  generate "devise:views"

  # Create Devise User
  generate :devise, "User",
           "first_name",
           "last_name",
           "announcements_last_read_at:datetime",
           "admin:boolean"

  # Set admin default to false
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  requirement = Gem::Requirement.new("> 5.2")
  rails_version = Gem::Version.new(Rails::VERSION::STRING)

  if requirement.satisfied_by? rails_version
    gsub_file "config/initializers/devise.rb",
      /  # config.secret_key = .+/,
      "  config.secret_key = Rails.application.credentials.secret_key_base"
  end

  # Add Devise masqueradable to users
  inject_into_file("app/models/user.rb", "omniauthable, :masqueradable, :", after: "devise :")
end

def add_tailwindcss
  # Remove Application CSS
  run "rm app/assets/stylesheets/application.css"

  # Install Tailwind CSS
  generate "tailwindcss:install"

  # Add Turbolinks JS & LocalTime JavaScript
  run "yarn add rails-ujs turbolinks local-time"

  insert_into_file(
    "app/javascript/packs/application.js",
    "\nimport Rails from 'rails-ujs'\nimport Turbolinks from 'turbolinks'\nimport LocalTime from 'local-time'\n\nRails.start()\nTurbolinks.start()\nLocalTime.start()",
    after: "console.log('Hello World from Webpacker')"
  )
end

def copy_templates
  directory "app", force: true
  directory "config", force: true
  directory "lib", force: true

  route "get '/terms', to: 'home#terms'"
  route "get '/privacy', to: 'home#privacy'"
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  insert_into_file "config/routes.rb",
    "  authenticate :user, lambda { |u| u.admin? } do\n    mount Sidekiq::Web => '/sidekiq'\n  end\n\n",
    after: "Rails.application.routes.draw do\n"
end

def add_foreman
  copy_file "~/dev/rails-template/Procfile"
end

def add_announcements
  generate "model Announcement published_at:datetime announcement_type name description:text"
  route "resources :announcements, only: [:index]"
end

def add_notifications
  generate "model Notification recipient_id:bigint actor_id:bigint read_at:datetime action:string notifiable_id:bigint notifiable_type:string"
  route "resources :notifications, only: [:index]"
end

def add_administrate
  generate "administrate:install"

  gsub_file "app/dashboards/announcement_dashboard.rb",
    /announcement_type: Field::String/,
    "announcement_type: Field::Select.with_options(collection: Announcement::TYPES)"

  gsub_file "app/dashboards/user_dashboard.rb",
    /email: Field::String/,
    "email: Field::String,\n    password: Field::String.with_options(searchable: false)"

  gsub_file "app/dashboards/user_dashboard.rb",
    /FORM_ATTRIBUTES = \[/,
    "FORM_ATTRIBUTES = [\n    :password,"

  gsub_file "app/controllers/admin/application_controller.rb",
    /# TODO Add authentication logic here\./,
    "redirect_to '/', alert: 'Not authorized.' unless user_signed_in? && current_user.admin?"
end

def add_app_helpers_to_administrate
  environment do <<-RUBY
    # Expose our application's helpers to Administrate
    config.to_prepare do
      Administrate::ApplicationController.helper #{@app_name.camelize}::Application.helpers
    end
  RUBY
  end
end

def add_multiple_authentication
    insert_into_file "config/routes.rb",
    ', controllers: { omniauth_callbacks: "users/omniauth_callbacks" }',
    after: "  devise_for :users"

    generate "model Service user:references provider uid access_token access_token_secret refresh_token expires_at:datetime auth:text"

    template = """
    env_creds = Rails.application.credentials[Rails.env.to_sym] || {}
    %w{ twitter google_oauth2 }.each do |provider|
      if options = env_creds[provider]
        confg.omniauth provider, options[:app_id], options[:app_secret], options.fetch(:options, {})
      end
    end
    """.strip

    insert_into_file "config/initializers/devise.rb", "  " + template + "\n\n",
          before: "  # ==> Warden configuration"
end

def add_whenever
  run "wheneverize ."
end

def add_friendly_id
  generate "friendly_id"

  insert_into_file(
    Dir["db/migrate/**/*friendly_id_slugs.rb"].first,
    "[5.2]",
    after: "ActiveRecord::Migration"
  )
end

def stop_spring
  run "spring stop"
end

def add_sitemap
  rails_command "sitemap:install"
end

# Main setup
add_template_repository_to_source_path

add_gems

after_bundle do
  set_application_name
  stop_spring
  add_minitest
  # add_root
  add_users
  add_tailwindcss
  add_sidekiq
  add_foreman
  add_announcements
  add_notifications
  add_multiple_authentication
  add_friendly_id

  copy_templates

  # Migrate
  rails_command "db:create"
  rails_command "db:migrate"

  # Migrations must be done before this
  add_administrate

  add_app_helpers_to_administrate

  add_whenever

  add_sitemap

  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
