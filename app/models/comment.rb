class Comment < ApplicationRecord
  include MeiliSearch::Rails

  belongs_to :user
  has_many :notifications, dependent: :nullify

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :recent, -> { order(created_at: :desc) }

  meilisearch enqueue: true, index_uid: "comments" do
    attribute :body
    attribute :user_username do
      user.username
    end
    attribute :created_at_timestamp do
      created_at.to_i
    end
    searchable_attributes [:body, :user_username]
    sortable_attributes [:created_at_timestamp]
  end

  MENTION_REGEX = /@([a-zA-Z0-9_]+)/

  after_save_commit :enqueue_mention_scan, if: :saved_change_to_body?

  def mentioned_usernames
    body.to_s.scan(MENTION_REGEX).flatten.map(&:downcase).uniq
  end

  private

  def enqueue_mention_scan
    MentionScannerJob.perform_later(id)
  end
end
