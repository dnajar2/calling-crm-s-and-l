class CalendarsController < ApplicationController
  skip_before_action :authenticate_request!, only: [ :public_availability, :public_create_event, :public_delete_last_event ]
  before_action :set_calendar, only: [ :show, :update, :destroy, :availability ]

  # GET /calendars/lookup_by_email?email=user@example.com
  # Returns calendar public tokens for a user by email (for n8n integration)
  def lookup_by_email
    email = params[:email]
    return render json: { error: "Email parameter required" }, status: :bad_request if email.blank?

    user = User.find_by(email: email)
    return render json: { error: "User not found" }, status: :not_found unless user

    calendars = user.calendars.map do |calendar|
      {
        id: calendar.id,
        name: calendar.name,
        public_token: calendar.public_token,
        timezone: calendar.timezone
      }
    end

    render json: {
      email: user.email,
      user_name: user.name,
      calendars: calendars
    }
  end

  # GET /calendars
  def index
    render json: current_user.calendars
  end

  # GET /calendars/:id
  def show
    render json: @calendar
  end

  # POST /calendars
  def create
    calendar = current_user.calendars.build(calendar_params)

    if calendar.save
      render json: calendar, status: :created
    else
      render json: { errors: calendar.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /calendars/:id
  def update
    if @calendar.update(calendar_params)
      render json: @calendar
    else
      render json: { errors: @calendar.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /calendars/:id
  def destroy
    @calendar.destroy
    head :no_content
  end

  # GET /calendars/:id/availability?date=YYYY-MM-DD
  def availability
    date = params[:date].presence || Date.current

    slots = CalendarAvailability.new(@calendar, date).slots

    render json: { date: date.to_s, slots: slots }
  end

  # GET /calendars/public/:token/availability?date=YYYY-MM-DD
  # Public endpoint - no authentication required
  def public_availability
    calendar = Calendar.find_by!(public_token: params[:token])
    date = params[:date].presence || Date.current

    slots = CalendarAvailability.new(calendar, date).slots

    render json: {
      calendar_name: calendar.name,
      timezone: calendar.timezone,
      date: date.to_s,
      slots: slots
    }
  end

  # DELETE /calendars/public/:token/events/last
  # Public endpoint - no authentication required
  # Deletes the most recent event for testing purposes
  def public_delete_last_event
    calendar = Calendar.find_by!(public_token: params[:token])

    last_event = calendar.events.order(created_at: :desc).first

    if last_event
      last_event.destroy
      render json: {
        success: true,
        message: "Last event deleted successfully",
        deleted_event: {
          id: last_event.id,
          title: last_event.title,
          start_time: last_event.start_time.iso8601,
          client_name: last_event.client.name
        }
      }
    else
      render json: {
        success: false,
        message: "No events found to delete"
      }, status: :not_found
    end
  end

  # POST /calendars/public/:token/events
  # Public endpoint - no authentication required
  # Creates an event and optionally creates/finds a client
  def public_create_event
    calendar = Calendar.find_by!(public_token: params[:token])

    # Find or create client
    client = find_or_create_client(calendar.user, public_event_params[:client])

    # Create event
    event = calendar.events.build(
      client: client,
      title: public_event_params[:title],
      description: public_event_params[:description],
      start_time: public_event_params[:start_time],
      end_time: public_event_params[:end_time]
    )

    if event.save
      render json: {
        success: true,
        message: "Event created successfully",
        event: {
          id: event.id,
          calendar_id: event.calendar_id,
          title: event.title,
          description: event.description,
          start_time: event.start_time.iso8601,
          end_time: event.end_time.iso8601,
          created_at: event.created_at.iso8601
        },
        client: {
          id: client.id,
          name: client.name,
          email: client.email,
          phone: client.phone
        },
        calendar: {
          id: calendar.id,
          name: calendar.name,
          timezone: calendar.timezone
        }
      }, status: :created
    else
      render json: {
        success: false,
        errors: event.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def find_or_create_client(user, client_params)
    return nil if client_params.blank?

    # Pre-normalize email for consistent lookup
    normalized_email = normalize_email_for_lookup(client_params[:email])

    # Try to find existing client by normalized email
    client = user.clients.find_by(email: normalized_email) if normalized_email.present?

    # If not found by email, try by phone (if provided)
    if !client && client_params[:phone].present?
      normalized_phone = normalize_phone_for_lookup(client_params[:phone])
      client = user.clients.find_by(phone: normalized_phone) if normalized_phone.present?
    end

    # Create new client if not found
    unless client
      client = user.clients.create!(
        name: client_params[:name],
        email: normalized_email,
        phone: client_params[:phone]
      )
    end

    client
  end

  def normalize_email_for_lookup(email)
    return nil if email.blank?

    email.to_s
      .downcase
      .strip
      .gsub(/\s+/, "")
      .gsub(/\bat\b/, "@")
      .gsub(/\bdot\b/, ".")
  end

  def normalize_phone_for_lookup(phone)
    return nil if phone.blank?

    # Remove all non-numeric characters
    cleaned = phone.gsub(/[^\d]/, "")

    # Convert to E.164 format for consistent lookup
    if cleaned.match?(/^\d{10}$/)
      "+1#{cleaned}"
    elsif cleaned.match?(/^1\d{10}$/)
      "+#{cleaned}"
    else
      "+1#{cleaned}" # Assume US number
    end
  end

  def public_event_params
    params.require(:event).permit(
      :title,
      :description,
      :start_time,
      :end_time,
      client: [ :name, :email, :phone ]
    )
  end

  def set_calendar
    @calendar = current_user.calendars.find(params[:id])
  end

  def calendar_params
    params.require(:calendar).permit(:name)
  end
end
