FactoryBot.define do
  factory :comment do
    user
    body { "Hello world!" }
  end
end
