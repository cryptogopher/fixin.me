class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Statuses ordered by decreasing privileges
  enum :status, {
    admin: 1,       # admin level access
    active: 2,      # read-write user level access
    restricted: 3,  # read-only user level access
    locked: 4,      # disallowed to sign in due to failed logins
    disabled: 5     # administratively disallowed to sign in
  }, default: :active
end
