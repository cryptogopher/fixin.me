require 'application_system_test_case'

# NOTE: remove constant to avoid warnings due to double loading of
# rails/tasks/statistics.rake. To be removed after upgrade to Rails 8.1.
Object.send(:remove_const, :STATS_DIRECTORIES)

Rails.application.load_tasks
# NOTE: for some reason task for checking pending migrations messes up
# transaction when run during test. It causes all DB changes made before its
# execution to be rolled back.
# Run it before tests, so any rake task dependent on it will see it as
# #already_invoked and won't run it during test. It is redundant anyway, as
# migrations are run before starting test suite.
Rake::Task['db:abort_if_pending_migrations'].invoke

class TasksTest < ApplicationSystemTestCase
  test "db:seed creates admin account" do
    User.admin.delete_all
    assert_output /Creating admin account/ do
      Rake::Task['db:seed'].execute
    end
    assert User.admin.exists?
  end
end
