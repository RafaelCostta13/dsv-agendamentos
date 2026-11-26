class LoginAttempt < ApplicationRecord
  KINDS = %w[email ip].freeze
  validates :key_kind, inclusion: { in: KINDS }
  validates :key_digest, length: { is: 64 }
  validates :occurred_at, presence: true
end
