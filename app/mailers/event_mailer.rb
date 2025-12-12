class EventMailer < ApplicationMailer
  def client_notification(event)
    @event = event
    @client = event.client
    @user = event.calendar.user

    # Generate and attach ICS file
    ics_content = IcsGeneratorService.generate(event)
    attachments["event.ics"] = {
      mime_type: "text/calendar",
      content: ics_content
    }

    mail(
      to: @client.email,
      subject: "Appointment Confirmed: #{event.title}"
    )
  end

  def user_notification(event)
    @event = event
    @client = event.client
    @user = event.calendar.user

    # Generate and attach ICS file
    ics_content = IcsGeneratorService.generate(event)
    attachments["event.ics"] = {
      mime_type: "text/calendar",
      content: ics_content
    }

    mail(
      to: @user.email,
      subject: "New Event Scheduled: #{event.title}"
    )
  end
end
