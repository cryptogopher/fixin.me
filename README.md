# README

Quantified self

* Ruby version: 3.1
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

    bundle exec rails s -e production


### Apache mod_passenger



## Contributing


### Database

Grant database user privileges for development and test environments,
possibly with different Ruby versions:

    > mysql -p
    mysql> create user `fixinme-dev`@localhost identified by '<some password>';
    mysql> grant all privileges on `fixinme-%`.* to `fixinme-dev`@localhost;
    mysql> flush privileges;


### Development environment

Starting application server in development environment:

    bundle exec rails s -e development

For running rake tasks, prepend command with environment:

    RAILS_ENV="development" bundle exec rake ...


### Running tests

Tests need to be run from within toplevel application directory:

* all system tests:

    bundle exec rails test:system

* all tests from one file, with optional seed:

    bundle exec rails test test/system/users_test.rb --seed 1234

* single test, with optional seed:

    bundle exec rails test test/system/users_test.rb --name test_register --seed 1234
