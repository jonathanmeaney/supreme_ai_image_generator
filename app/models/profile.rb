class Profile < ApplicationRecord
  belongs_to :user

  encrypts :first_name, deterministic: true
  encrypts :last_name, deterministic: true
  encrypts :dob, deterministic: true

  validates :first_name, :last_name, :dob, presence: true
  belongs_to :user
end
