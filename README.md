# Comments & Notifications — Rails 8

Rails 8 application with comments, user mentions, real-time notifications, and Meilisearch-powered full-text search.

## Stack

- **Rails 8.1** on Ruby 3.3.6
- **PostgreSQL** as primary DB
- **Devise** for authentication
- **Meilisearch** for comment full-text search (via `meilisearch-rails`)
- **Hotwire (Turbo + Stimulus)** with **Turbo Streams over ActionCable** (Solid Cable) for real-time notifications
- **Solid Queue** for background jobs (mention scanning, search indexing)
- **TailwindCSS** for styling

## Features

- User registration / login / logout (Devise, with unique `username` for `@mentions`)
- Create / edit / delete comments (RESTful, owner-only authorization)
- `@username` mentions inside a comment body create a `Notification` for the mentioned user
- Notifications appear in real time via Turbo Stream broadcasts — no page reload needed
- Mark single notification or all as read
- Full-text search across comments via Meilisearch (`/comments/search?q=...`)

## Prerequisites

- Ruby **3.3.6** (`rbenv install 3.3.6` if missing)
- Docker / Docker Compose (for Postgres + Meilisearch)
- Bundler

## Setup

```bash
# 1. Start Postgres + Meilisearch
docker compose up -d

# 2. Install gems
bundle install

# 3. Copy env defaults (optional — defaults work out of the box)
cp .env.example .env

# 4. Create DB, run migrations, seed
bin/rails db:setup       # creates DB + runs migrations + seeds
# (or step by step: bin/rails db:create db:migrate db:seed)

# 5. Run the app + Tailwind watcher + job runner
bin/dev
```

The app listens on `http://localhost:3000`.

### Seeded users

| Username | Email | Password |
|---|---|---|
| `alice` | `alice@example.com` | `password` |
| `bob` | `bob@example.com` | `password` |
| `carol` | `carol@example.com` | `password` |

## Verifying the features

1. **Login**: visit `/users/sign_in` and log in as `alice`.
2. **Post with mention**: post a comment containing `@bob` from alice.
3. **Real-time notification**: open another browser/private window, log in as `bob`. The notification badge updates without a page reload as soon as alice posts. Open `/notifications` to see the list.
4. **Mark as read**: click "Mark read" — badge count decrements live.
5. **Edit/Delete**: only the comment's author sees Edit/Delete buttons; visiting `/comments/:id/edit` for someone else's comment redirects with an alert.
6. **Search**: use the search box at the top of the comments page — results come from Meilisearch (`Comment.search(q)`).

## Reindex Meilisearch

```bash
bin/rails runner 'Comment.reindex!'
```

Or query Meilisearch directly:

```bash
curl -s -H "Authorization: Bearer masterKey" \
  "http://localhost:7700/indexes/comments/search" \
  -d '{"q":"Meilisearch"}'
```

## Services

- Postgres: `localhost:5432` (user `postgres`, password `postgres`)
- Meilisearch: `localhost:7700` (master key `masterKey`)

## Tests

```bash
bin/rails test
```

## Project layout highlights

- `app/models/comment.rb` — `MeiliSearch::Rails` index, mention parsing, after-commit job
- `app/models/notification.rb` — Turbo Stream broadcasts on `after_create_commit`
- `app/jobs/mention_scanner_job.rb` — parses `@username` mentions and creates notifications
- `app/controllers/comments_controller.rb` — REST + `#search` action
- `app/controllers/notifications_controller.rb` — index, mark-as-read, mark-all-as-read
- `app/views/layouts/application.html.erb` — global `turbo_stream_from current_user, :notifications`
