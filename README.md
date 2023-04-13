# README

Quantified self

* Ruby version: 2.7
* System dependencies: none


## Installation

    git clone https://gitea.michalczyk.pro/fixin.me/fixin.me.git
    bundle config set --local path '.gem'
    bundle install


## Configuration

    cp -a config/application.rb.dist config/application.rb

Modify configuration settings below `SETUP` comment appropriately.


## Database

Grant database user and privileges:

    > mysql -p
    mysql> create user fixinme@localhost identified by '<some password>';
    mysql> grant all privileges on fixinme.* to fixinme@localhost;
    mysql> flush privileges;

Copy config template and update database configuration:

    cp -a config/database.yml.dist config/database.yml

Run database creation and migration tasks:

    RAILS_ENV="production" bundle exec rake db:create db:migrate db:seed


## Running


### Standalone Rails server + Apache proxy

Copy Puma config template:

    cp -a config/puma.rb.dist config/puma.rb

and specify server IP/port, either with `port` or `bind`, e.g.:

    bind 'tcp://0.0.0.0:3000'

Run server

    RAILS_ENV="production" bin/rails s


### Apache mod_passenger


## Contributing


### Database

Grant database user privileges for development and test environments,
possibly with different Ruby versions:

    > mysql -p
    mysql> create user `fixinme-dev`@localhost identified by '<some password>';
    mysql> grant all privileges on `fixinme-%`.* to `fixinme-dev`@localhost;
    mysql> flush privileges;


### Environment

Use `RAILS_ENV="development"` for rake commands and running rails server.

Use `RAILS_ENV="test"` for running tests.


### Running tests

Single test:

    bin/rails test test/system/users_test.rb --name test_register
