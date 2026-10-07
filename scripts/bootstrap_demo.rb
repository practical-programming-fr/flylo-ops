# frozen_string_literal: true
# Run inside the rails container:
#   bundle exec rails runner /tmp/bootstrap_demo.rb
# Env: TRIAGE_WEBHOOK_URL, CHATWOOT_ADMIN_EMAIL, CHATWOOT_ADMIN_PASSWORD, CHATWOOT_ACCOUNT_NAME

require "securerandom"

email = ENV.fetch("CHATWOOT_ADMIN_EMAIL", "admin@flylo.local")
password = ENV.fetch("CHATWOOT_ADMIN_PASSWORD", "FlyloDemo123!")
account_name = ENV.fetch("CHATWOOT_ACCOUNT_NAME", "FlyLo Demo")
triage_url = ENV.fetch("TRIAGE_WEBHOOK_URL", "http://host.docker.internal:4001/webhooks/chatwoot")

user = User.find_by(email: email)
unless user
  user = User.new(
    name: "FlyLo Admin",
    email: email,
    password: password,
    password_confirmation: password,
  )
  user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
  user.confirmed_at = Time.current if user.respond_to?(:confirmed_at=)
  user.save!
end

account = Account.find_by(name: account_name) || Account.create!(name: account_name)
AccountUser.find_or_create_by!(account: account, user: user) do |au|
  au.role = :administrator if au.respond_to?(:role=)
end

inbox = account.inboxes.find_by(name: "Guest Care Email")
unless inbox
  channel = nil
  if defined?(Channel::Email)
    begin
      attrs = {
        account: account,
        email: "guestcare@flylo.local",
      }
      # Attribute names vary across Chatwoot versions — try common ones.
      channel = Channel::Email.new(attrs)
      %i[
        smtp_address smtp_port smtp_login smtp_password smtp_domain
        smtp_enable_starttls_auto smtp_authentication
      ].each do |key|
        next unless channel.respond_to?("#{key}=")
      end
      channel.smtp_address = "mailpit" if channel.respond_to?(:smtp_address=)
      channel.smtp_port = 1025 if channel.respond_to?(:smtp_port=)
      channel.smtp_domain = "flylo.local" if channel.respond_to?(:smtp_domain=)
      channel.smtp_enable_starttls_auto = false if channel.respond_to?(:smtp_enable_starttls_auto=)
      channel.save!
    rescue StandardError => e
      warn "Email channel create failed (#{e.class}: #{e.message}); falling back to API inbox"
      channel = nil
    end
  end
  channel ||= Channel::Api.create!(account: account, webhook_url: triage_url)
  inbox = account.inboxes.create!(name: "Guest Care Email", channel: channel)
end

InboxMember.find_or_create_by!(inbox: inbox, user: user)

token = user.access_token&.token
if token.blank?
  if user.respond_to?(:create_access_token!)
    access = user.create_access_token!
    token = access.token
  elsif defined?(AccessToken)
    access = AccessToken.find_or_create_by!(owner: user) do |t|
      t.token = SecureRandom.hex(32)
    end
    token = access.token
  end
end

webhook = account.webhooks.find_by(url: triage_url)
webhook ||= account.webhooks.create!(
  url: triage_url,
  name: "FlyLo Triage",
  subscriptions: %w[conversation_created message_created],
)

puts "CHATWOOT_BASE_URL=http://localhost:3001"
puts "CHATWOOT_ACCOUNT_ID=#{account.id}"
puts "CHATWOOT_INBOX_ID=#{inbox.id}"
puts "CHATWOOT_USER_ACCESS_TOKEN=#{token}"
puts "CHATWOOT_WEBHOOK_ID=#{webhook.id}"
puts "CHATWOOT_ADMIN_EMAIL=#{email}"
puts "CHATWOOT_ADMIN_PASSWORD=#{password}"
puts "TRIAGE_WEBHOOK_URL=#{triage_url}"
