puts "Seeding users..."

users_data = [
  { username: "alice", email: "alice@example.com" },
  { username: "bob",   email: "bob@example.com" },
  { username: "carol", email: "carol@example.com" }
]

users = users_data.map do |attrs|
  User.find_or_create_by!(email: attrs[:email]) do |u|
    u.username = attrs[:username]
    u.password = "password"
    u.password_confirmation = "password"
  end
end

alice, bob, carol = users

puts "Seeding comments..."

[
  [alice, "Hey everyone, welcome to the new comments app!"],
  [bob,   "Thanks @alice for setting this up."],
  [carol, "I love how @alice and @bob handled the launch."],
  [alice, "Let me know if anyone needs help with anything."],
  [bob,   "@carol can you review the latest design?"],
  [carol, "Sure @bob, will do today."],
  [alice, "Search should be working through Meilisearch now."],
  [bob,   "Nice work @alice on the search feature."],
  [carol, "Just tested mentions — notifications popped up in real time!"],
  [alice, "Glad to hear it, @carol. Ping me if anything breaks."]
].each do |user, body|
  comment = Comment.create!(user: user, body: body)
  MentionScannerJob.perform_now(comment.id)
end

puts "Done. Created #{User.count} users and #{Comment.count} comments."
