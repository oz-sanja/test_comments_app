FactoryBot.define do
  factory :notification do
    recipient factory: :user
    actor factory: :user
    comment
    notification_type { "mention" }
    read_at { nil }
  end
end
