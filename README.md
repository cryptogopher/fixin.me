README
======

Quantified self


Installation
------------

The steps described in this section are for preparing a production installation.
For possible modifications to this procedure to configure the development
environment, see the _Contributing_ section below.

### Requirements

* Server side:
    * Ruby interpreter, depending on the version of Rails used (see _Gemfile_),
        * https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#ruby-versions
    * database (e.g. MySQL >= 8.0) supporting:
        * recursive Common Table Expressions (CTE) for SELECT/UPDATE/DELETE,
            * MariaDB does not support CTE for UPDATE/DELETE
              (https://jira.mariadb.org/browse/MDEV-18511)
        * decimal datatype with precision of at least 30,
            * SQLite3 _flexible typing_ decimal will work, but precision
              will be limited to 16, making it practical mostly for testing
              purposes
    * for testing: browser as specified in _Client side_ requirements
* Client side:
    * browser (e.g. Firefox >= 121) supporting:
        * [`import maps`](https://caniuse.com/import-maps)
          (required by `importmap-rails` gem >= 2.0)
        * CSS [`:has()` pseudo-class](https://caniuse.com/css-has)

### Gems

On systems where development tools and libraries are not installed by default
(such as Ubuntu), you should install them before proceeding with Ruby gems.
Select the database client library according to the database engine you are
planning to use:

    sudo apt install build-essential libyaml-dev libmysqlclient-dev

    git clone https://gitea.michalczyk.pro/fixin.me/fixin.me.git
    cd fixin.me
    bundle config --local frozen true
    bundle config --local path .gem

Select which database engine gem to install (mysql, postgresql, sqlite):

    bundle config --local with mysql
    bundle install

### Configuration

Customize application settings (starting below `SETUP` comment) appropriately:

    cp -a config/application.rb.dist config/application.rb

Create `secret_key_base`. It will be automatically generated on first
`credentials:edit`, so it's enough to run command below, save the file and exit
editor:

    bundle exec rails credentials:edit

### Database

Grant database user and privileges:

    > mysql -p
    mysql> create user fixinme@localhost identified by 'Some-password1%';
    mysql> grant all privileges on fixinme.* to fixinme@localhost;
    mysql> flush privileges;

Copy config template and update database configuration:

    cp -a config/database.yml.dist config/database.yml

Run database creation and migration tasks:

    RAILS_ENV="production" bundle exec rake db:create db:migrate db:seed


Running
-------

### Standalone Rails server + Apache proxy

Customize Puma config template:

    cp -a config/puma.rb.dist config/puma.rb

and specify server IP/port, either with `port` or `bind`, e.g.:

    bind 'tcp://0.0.0.0:3000'

#### (option 1) Start server manually

    bundle exec rails s -e production

#### (option 2) Start server as systemd service

Customize service template, setting at least `User` and `WorkingDirectory`:

    sudo cp bin/fixinme.service.dist /etc/systemd/system/fixinme.service

    sudo systemctl daemon-reload
    sudo systemctl enable fixin.service
    sudo systemctl start fixin.service

    sudo systemctl status fixin.service

### Apache mod_passenger

TODO: add sample configuration


Contributing
------------

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

* system test(s) with seed/test name specified:

        bundle exec rails test:system --seed 64690 --name test_add_unit

* all tests from one file, with optional seed:

        bundle exec rails test test/system/users_test.rb --seed 1234


### Icons

Pictogrammers Material Design Icons: https://pictogrammers.com/library/mdi/


### Rake tasks

Exporting default settings defined in application to seed file (e.g. to send as
PR or share between installations):

        bundle exec rails db:seed:export
