# Rails Quickstart

Based on [Jumpstart Rails](http://jumpstartrails.com/) and inspired by [Laravel Spark](https://spark.laravel.com/).

**Note:** Requires Rails 5.2

## Getting Started

#### Requirements

You'll need the following installed to run the template successfully:

* Ruby 2.5+
* bundler - `gem install bundler`
* rails - `gem install rails`
* Yarn - `brew install yarn` or [Install Yarn](https://yarnpkg.com/en/docs/install)

#### Add a `.railsrc` to your home directory

You’ll need to add a `.railsrc` to your home directory for Rails Quickstart to work. Remember to update the `--template=` path to your local copy of Rails Quickstart:

```bash

# ~/.railsrc

--database=postgresql
--webpack
--skip-coffee
--template=~/[path-to-rails-quickstart]/rails_template.rb
```

#### Creating a new app

```bash
rails new myapp
```

#### Authenticate with social networks

We use the encrypted Rails Credentials for app_id and app_secrets when it comes to omniauth authentication. Edit them as so:

```
EDITOR=vim rails credentials:edit
```

Make sure your file follow this structure:

```yml
secret_key_base: [your-key]
development:
  github:
    app_id: something
    app_secret: something
    options:
      scope: 'user:email'
      whatever: true
production:
  github:
    app_id: something
    app_secret: something
    options:
      scope: 'user:email'
      whatever: true
```

With the environment, the service and the app_id/app_secret. If this is done correctly, you should see login links
for the services you have added to the encrypted credentials using `EDITOR=vim rails credentials:edit`

#### Cleaning up

```bash
rails db:drop
spring stop
cd ..
rm -rf myapp
```
