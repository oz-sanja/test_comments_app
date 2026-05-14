require "rails_helper"

RSpec.describe MentionScannerJob, type: :job do
  let(:alice) { create(:user, username: "alice") }
  let(:bob)   { create(:user, username: "bob") }
  let(:carol) { create(:user, username: "carol") }

  it "creates a Notification for each mentioned user, excluding the author" do
    _ = [alice, bob, carol]
    comment = create(:comment, user: alice, body: "Hey @bob and @carol, also @alice")

    expect {
      described_class.perform_now(comment.id)
    }.to change(Notification, :count).by(2)

    recipients = Notification.where(comment: comment).pluck(:recipient_id)
    expect(recipients).to match_array([bob.id, carol.id])
    expect(Notification.where(comment: comment).pluck(:notification_type).uniq).to eq(["mention"])
    expect(Notification.where(comment: comment).pluck(:actor_id).uniq).to eq([alice.id])
  end

  it "is idempotent — does not duplicate notifications when run twice" do
    _ = [alice, bob]
    comment = create(:comment, user: alice, body: "hi @bob")

    described_class.perform_now(comment.id)
    expect {
      described_class.perform_now(comment.id)
    }.not_to change(Notification, :count)
  end

  it "ignores mentions of unknown usernames" do
    comment = create(:comment, user: alice, body: "hi @ghost")
    expect {
      described_class.perform_now(comment.id)
    }.not_to change(Notification, :count)
  end

  it "matches usernames case-insensitively" do
    _ = bob
    comment = create(:comment, user: alice, body: "yo @BOB")
    expect {
      described_class.perform_now(comment.id)
    }.to change(Notification, :count).by(1)
  end

  it "does nothing when the comment was deleted before the job ran" do
    expect {
      described_class.perform_now(-1)
    }.not_to raise_error
  end
end
