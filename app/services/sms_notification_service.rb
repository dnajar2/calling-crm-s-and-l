require "twilio-ruby"

class SmsNotificationService
  def self.send_event_confirmation(event)
    Rails.logger.info("=== SMS Notification Starting for Event ##{event.id} ===")

    if event.client.phone.blank?
      Rails.logger.warn("SMS skipped: Client ##{event.client.id} has no phone number")
      return
    end

    Rails.logger.info("Original phone number: #{event.client.phone}")
    phone_number = normalize_phone_number(event.client.phone)

    unless phone_number
      Rails.logger.error("SMS failed: Phone normalization failed for #{event.client.phone}")
      return
    end

    Rails.logger.info("Normalized phone number: #{phone_number}")

    # In development, override recipient to prevent sending to real clients
    if Rails.env.development? && ENV["DEV_SMS_OVERRIDE_NUMBER"].present?
      original_number = phone_number
      phone_number = ENV["DEV_SMS_OVERRIDE_NUMBER"]
      Rails.logger.warn("🔧 DEV MODE: Redirecting SMS from #{original_number} to #{phone_number}")
    end

    Rails.logger.info("Twilio Config - Account SID: #{ENV['TWILIO_ACCOUNT_SID']&.first(10)}...")
    Rails.logger.info("Twilio Config - From Number: #{ENV['TWILIO_PHONE_NUMBER']}")

    client = Twilio::REST::Client.new(
      ENV["TWILIO_ACCOUNT_SID"],
      ENV["TWILIO_AUTH_TOKEN"]
    )

    message_body = build_message(event)
    Rails.logger.info("Message body: #{message_body}")

    begin
      # Use Messaging Service SID if available, otherwise use phone number
      message_params = {
        to: phone_number,
        body: message_body
      }

      if ENV["TWILIO_MESSAGING_SERVICE_SID"].present?
        message_params[:messaging_service_sid] = ENV["TWILIO_MESSAGING_SERVICE_SID"]
        Rails.logger.info("Using Messaging Service SID: #{ENV['TWILIO_MESSAGING_SERVICE_SID']}")
      else
        message_params[:from] = ENV["TWILIO_PHONE_NUMBER"]
        Rails.logger.info("Using From Number: #{ENV['TWILIO_PHONE_NUMBER']}")
      end

      response = client.messages.create(**message_params)
      Rails.logger.info("✅ SMS sent successfully!")
      Rails.logger.info("Twilio Message SID: #{response.sid}")
      Rails.logger.info("Status: #{response.status}")
    rescue Twilio::REST::RestError => e
      Rails.logger.error("❌ Twilio API Error:")
      Rails.logger.error("  Error Code: #{e.code}")
      Rails.logger.error("  Error Message: #{e.message}")
      Rails.logger.error("  More Info: #{e.more_info}")
      Rails.logger.error("  Full Error: #{e.inspect}")
    rescue => e
      Rails.logger.error("❌ Unexpected error sending SMS:")
      Rails.logger.error("  #{e.class}: #{e.message}")
      Rails.logger.error("  Backtrace: #{e.backtrace.first(5).join("\n  ")}")
    end

    Rails.logger.info("=== SMS Notification Complete ===")
  end

  def self.normalize_phone_number(phone)
    return nil if phone.blank?

    # Remove all non-numeric characters except +
    cleaned = phone.gsub(/[^\d+]/, "")

    # If already in E.164 format, return it
    return cleaned if cleaned.match?(/^\+1\d{10}$/)

    # If it's 10 digits (area code + number), add +1
    if cleaned.match?(/^\d{10}$/)
      "+1#{cleaned}"
    # If it's 11 digits starting with 1, add +
    elsif cleaned.match?(/^1\d{10}$/)
      "+#{cleaned}"
    # If it starts with +, assume it's already international format
    elsif cleaned.match?(/^\+\d+$/)
      cleaned
    else
      # Invalid format, return nil
      Rails.logger.warn("Invalid phone number format: #{phone}")
      nil
    end
  end

  def self.build_message(event)
    time_info = if event.start_time.present?
      event.start_time.strftime('%B %d, %Y at %I:%M %p')
    else
      "Time TBD"
    end

    <<~MESSAGE
      Hi #{event.client.name}!

      Your appointment has been confirmed:
      📅 #{event.title}
      🕐 #{time_info}

      See you then!
    MESSAGE
  end
end
