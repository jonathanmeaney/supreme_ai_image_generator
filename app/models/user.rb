class User < ApplicationRecord
  has_secure_password
  has_one :profile

  validates :email, presence: true, uniqueness: true
  normalizes :email, with: -> (e) { e.strip.downcase }
end
