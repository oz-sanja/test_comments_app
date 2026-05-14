require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:recipient).class_name("User") }
    it { is_expected.to belong_to(:actor).class_name("User") }
    it { is_expected.to belong_to(:comment).optional }
  end

  describe "scopes" do
    let!(:unread) { create(:notification, read_at: nil) }
    let!(:read)   { create(:notification, read_at: 1.hour.ago) }

    it ".unread returns only unread notifications" do
      expect(Notification.unread).to contain_exactly(unread)
    end

    it ".recent orders by created_at desc" do
      expect(Notification.recent.first.created_at).to be >= Notification.recent.last.created_at
    end
  end

  describe "#read?" do
    it "is false when read_at is nil" do
      expect(build(:notification, read_at: nil).read?).to be false
    end

    it "is true when read_at is set" do
      expect(build(:notification, read_at: Time.current).read?).to be true
    end
  end

  describe "#mark_as_read!" do
    it "sets read_at on an unread notification" do
      n = create(:notification, read_at: nil)
      expect { n.mark_as_read! }.to change { n.reload.read_at }.from(nil)
    end

    it "is a no-op when already read" do
      original_time = 2.days.ago
      n = create(:notification, read_at: original_time)
      expect { n.mark_as_read! }.not_to change { n.reload.read_at.to_i }
    end
  end

  describe "after_create_commit broadcast" do
    it "invokes broadcast_prepend_to and broadcast_replace_to on create" do
      recipient = create(:user)
      actor = create(:user)
      comment = create(:comment, user: actor)

      prepended = []
      replaced = []
      allow_any_instance_of(Notification).to receive(:broadcast_prepend_to) { |_self, *args, **kw| prepended << [args, kw] }
      allow_any_instance_of(Notification).to receive(:broadcast_replace_to) { |_self, *args, **kw| replaced << [args, kw] }

      Notification.create!(
        recipient: recipient,
        actor: actor,
        comment: comment,
        notification_type: "mention"
      )

      expect(prepended.size).to eq(1)
      expect(prepended.first[1][:target]).to eq("notifications_list")
      expect(replaced.size).to eq(1)
      expect(replaced.first[1][:target]).to eq("notifications_badge")
    end
  end
end
