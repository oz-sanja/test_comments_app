require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:alice) { create(:user, username: "alice") }
  let(:bob)   { create(:user, username: "bob") }

  describe "GET /notifications" do
    it "requires authentication" do
      get notifications_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists current_user's notifications" do
      mine    = create(:notification, recipient: alice, actor: bob)
      theirs  = create(:notification, recipient: bob,   actor: alice)
      sign_in alice
      get notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dom_id(mine))
      expect(response.body).not_to include(dom_id(theirs))
    end
  end

  describe "PATCH /notifications/:id/mark_as_read" do
    it "marks a notification as read for current_user" do
      n = create(:notification, recipient: alice, read_at: nil)
      sign_in alice
      patch mark_as_read_notification_path(n)
      expect(n.reload.read_at).not_to be_nil
    end

    it "does not allow marking another user's notification as read" do
      n = create(:notification, recipient: bob, read_at: nil)
      sign_in alice
      patch mark_as_read_notification_path(n)
      expect(response).to have_http_status(:not_found)
      expect(n.reload.read_at).to be_nil
    end
  end

  describe "PATCH /notifications/mark_all_as_read" do
    it "marks all current_user's unread notifications as read" do
      create_list(:notification, 3, recipient: alice, read_at: nil)
      create(:notification, recipient: bob, read_at: nil)
      sign_in alice
      patch mark_all_as_read_notifications_path
      expect(alice.notifications.unread.count).to eq(0)
      expect(bob.notifications.unread.count).to eq(1)
    end
  end

  def dom_id(record)
    ActionView::RecordIdentifier.dom_id(record)
  end
end
