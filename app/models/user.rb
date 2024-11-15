class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable

  # Statuses ordered by decreasing privileges
  enum :status, {
    admin: 4,       # admin level access
    active: 3,      # read-write user level access
    restricted: 2,  # read-only user level access
    locked: 1,      # disallowed to sign in due to failed logins; maintained by Devise :lockable
    disabled: 0,    # administratively disallowed to sign in
  }, default: :active

  has_many :units, dependent: :destroy

  def at_least(status)
    User.statuses[self.status] >= User.statuses[status]
  end
end
