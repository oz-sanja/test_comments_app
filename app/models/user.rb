class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable

  has_many :comments, dependent: :destroy
  has_many :notifications, foreign_key: :recipient_id,
                           class_name: "Notification",
                           dependent: :destroy

  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only letters, numbers, and underscores" },
            length: { in: 3..30 }

  def to_param
    username
  end
end
