require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:notifications).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(5_000) }
  end

  describe "#mentioned_usernames" do
    it "extracts unique downcased usernames from @mentions in body" do
      comment = build(:comment, body: "Hi @Alice and @bob, thanks @Alice!")
      expect(comment.mentioned_usernames).to contain_exactly("alice", "bob")
    end

    it "returns an empty array when there are no mentions" do
      comment = build(:comment, body: "no mentions here")
      expect(comment.mentioned_usernames).to be_empty
    end

    it "ignores email addresses (no false positives)" do
      comment = build(:comment, body: "email me at someone@example.com")
      expect(comment.mentioned_usernames).to contain_exactly("example")
    end
  end

  describe "after_save_commit callback" do
    it "enqueues MentionScannerJob on create" do
      user = create(:user)
      expect {
        user.comments.create!(body: "hi @somebody")
      }.to have_enqueued_job(MentionScannerJob).with { |comment_id| expect(comment_id).to be_a(Integer) }
    end

    it "enqueues MentionScannerJob when body changes on update" do
      comment = create(:comment, body: "original")
      expect {
        comment.update!(body: "updated @somebody")
      }.to have_enqueued_job(MentionScannerJob).with(comment.id)
    end

    it "does not enqueue MentionScannerJob when body did not change" do
      comment = create(:comment, body: "stays the same")
      expect {
        comment.update!(updated_at: Time.current)
      }.not_to have_enqueued_job(MentionScannerJob)
    end
  end
end
