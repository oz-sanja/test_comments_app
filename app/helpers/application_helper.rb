module ApplicationHelper
  MENTION_REGEX = /@([a-zA-Z0-9_]+)/

  def linkify_mentions(text)
    escaped = ERB::Util.html_escape(text.to_s)
    escaped.gsub(MENTION_REGEX) do
      username = Regexp.last_match(1)
      %(<span class="text-indigo-700 font-semibold bg-indigo-50 px-1 rounded">@#{username}</span>)
    end.html_safe
  end
end
