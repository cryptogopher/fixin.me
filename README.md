# README

Quantified self

* Ruby version: 2.7
* System dependencies: none


## Configuration

    cp -a config/application.rb.dist config/application.rb

Modify configuration settings below `SETUP` comment appropriately.


## Database

Create database user and grant privileges:

    > mysql -p
    mysql> create user fixinme@localhost identified by '<some password>';
    mysql> grant all privileges on fixinme.* to fixinme@localhost;
    mysql> flush privileges;

Copy config template and update database configuration:

    cp -a config/database.yml.dist config/database.yml

Run database creation and migration tasks:

    RAILS_ENV="production" bundle exec rake db:create db:migrate

## How to run the test suite: ...
