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
    * for testing: browser as specified in _Client side_ requirements
* Client side:
    * browser (e.g. Firefox >= 121) supporting:
        * [`import maps`](https://caniuse.com/import-maps)
          (required by `importmap-rails` gem >= 2.0)
        * CSS [`:has()` pseudo-class](https://caniuse.com/css-has)

### Gems

On systems where development tools and libraries are not installed by default
(such as Ubuntu), you should install them before proceeding with Ruby gems:

    sudo apt install build-essential libyaml-dev

    git clone https://gitea.michalczyk.pro/fixin.me/fixin.me.git
    cd fixin.me
    bundle config --local frozen true
    bundle config --local path .gem
    bundle install

### Configuration

Customize application settings (starting below `SETUP` comment) appropriately:

    cp -a config/application.rb.dist config/application.rb

Create `secret_key_base`. It will be automatically generated on first
`credentials:edit`, so it's enough to run command below, save the file and exit
editor:

    bundle exec rails credentials:edit

Precompile assets:

    RAILS_ENV=production bundle exec rails assets:precompile

### Database

Copy config template and update database configuration:

    cp -a config/database.yml.dist config/database.yml

Run database creation and migration tasks:

    RAILS_ENV=production bundle exec rails db:create db:migrate db:seed


Running
-------

### Standalone Rails server + Apache proxy

Copy and customize Puma config template if required:

    cp -a config/puma.rb.dist config/puma.rb

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

### Gems

Install development and testing gems:

    bundle config --local with development test

#### Using gems from local git repos

When working on gem PRs, it may be useful to work with proposed changes locally
until PRs get accepted upstream. To add gem hosted in local git repository:

    bundle config set local.capybara /var/www/tmp/capybara

Add gem to `Gemfile`:

  gem "capybara", git: "https://github.com/teamcapybara/capybara", branch: "branch-name"

and install:

    bundle install
    bundle show capybara

### Configuration

If you have previously precomiled assets for production environment, you should
clean them for development. Otherwise, if precompiled assets are available,
they will be served - even if they no longer match the original (uncompiled)
assets.

    bundle exec rails assets:clean

### Database

Dumping development data before database reset:

    TODO

### Development environment

Starting application server in development environment:

    bundle exec rails s -e development

For running rake tasks, prepend command with environment:

    RAILS_ENV=development bundle exec rails ...

### Running tests

Tests need to be run from within toplevel application directory:

* all system tests:

        bundle exec rails test:system

* system test(s) with seed or test name specified:

        bundle exec rails test:system --include test_add_unit --seed 64690

* all tests from one file, optionally with seed:

        bundle exec rails test test/system/users_test.rb --seed 1234

### Icons

Pictogrammers Material Design Icons: https://pictogrammers.com/library/mdi/

### Rake tasks

Exporting default settings defined in application to seed file (e.g. to send as
PR or share between installations):

        bundle exec rails db:seed:export
