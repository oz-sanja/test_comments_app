class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :comment, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_notification

  def read?
    read_at.present?
  end

  def mark_as_read!
    return if read?

    update!(read_at: Time.current)
  end

  private

  def broadcast_notification
    broadcast_prepend_to(
      [recipient, :notifications],
      target: "notifications_list",
      partial: "notifications/notification",
      locals: { notification: self }
    )
    broadcast_replace_to(
      [recipient, :notifications],
      target: "notifications_badge",
      partial: "shared/notifications_badge",
      locals: { count: recipient.notifications.unread.count }
    )
  end
end
