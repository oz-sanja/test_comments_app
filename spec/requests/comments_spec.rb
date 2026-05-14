require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:alice) { create(:user, username: "alice") }
  let(:bob)   { create(:user, username: "bob") }

  describe "GET /" do
    it "renders comments index publicly" do
      create(:comment, user: alice, body: "public comment")
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("public comment")
    end
  end

  describe "POST /comments" do
    context "when signed in" do
      before { sign_in alice }

      it "creates a comment owned by current_user" do
        expect {
          post comments_path, params: { comment: { body: "hello @bob" } }
        }.to change(Comment, :count).by(1)
        expect(Comment.last.user).to eq(alice)
      end

      it "rejects an empty comment" do
        expect {
          post comments_path, params: { comment: { body: "" } }
        }.not_to change(Comment, :count)
        expect(response).to have_http_status(:unprocessable_content).or have_http_status(:unprocessable_entity)
      end
    end

    context "when signed out" do
      it "redirects to login" do
        post comments_path, params: { comment: { body: "anon" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /comments/:id" do
    let!(:comment) { create(:comment, user: alice, body: "original") }

    it "lets the owner update their comment" do
      sign_in alice
      patch comment_path(comment), params: { comment: { body: "updated" } }
      expect(comment.reload.body).to eq("updated")
    end

    it "does not let a non-owner update someone else's comment" do
      sign_in bob
      patch comment_path(comment), params: { comment: { body: "hacked" } }
      expect(comment.reload.body).to eq("original")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /comments/:id" do
    let!(:comment) { create(:comment, user: alice) }

    it "lets the owner delete" do
      sign_in alice
      expect {
        delete comment_path(comment)
      }.to change(Comment, :count).by(-1)
    end

    it "does not let a non-owner delete" do
      sign_in bob
      expect {
        delete comment_path(comment)
      }.not_to change(Comment, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /comments/search" do
    it "returns the index template (search-by-body delegated to Meilisearch in production)" do
      get search_comments_path, params: { q: "" }
      expect(response).to have_http_status(:ok)
    end
  end
end
