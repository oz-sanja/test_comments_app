require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:notifications).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_length_of(:username).is_at_least(3).is_at_most(30) }
    it { is_expected.to allow_value("alice_01").for(:username) }
    it { is_expected.not_to allow_value("alice-01").for(:username) }
    it { is_expected.not_to allow_value("alice 01").for(:username) }
  end

  describe "#to_param" do
    it "returns the username so URLs use it instead of id" do
      user = build(:user, username: "alice")
      expect(user.to_param).to eq("alice")
    end
  end
end
