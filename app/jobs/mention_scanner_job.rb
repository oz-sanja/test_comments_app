class MentionScannerJob < ApplicationJob
  queue_as :default

  def perform(comment_id)
    comment = Comment.find_by(id: comment_id)
    return unless comment

    usernames = comment.mentioned_usernames - [comment.user.username.downcase]
    return if usernames.empty?

    User.where("LOWER(username) IN (?)", usernames).find_each do |user|
      next if user.id == comment.user_id
      next if Notification.exists?(recipient: user, comment: comment, notification_type: "mention")

      Notification.create!(
        recipient: user,
        actor: comment.user,
        comment: comment,
        notification_type: "mention"
      )
    end
  end
end
