class CalendarsController < ApplicationController
  include PublicTokenValidation

  skip_before_action :authenticate_request!, only: [ :public_availability, :public_create_event, :public_delete_last_event, :primary ]
  before_action :set_calendar, only: [ :show, :update, :destroy, :availability, :regenerate_token, :revoke_token, :extend_token, :token_stats ]

  # GET /calendars/primary?email=user@example.com
  # Returns the primary calendar for a user by email (for n8n integration and authenticated users)
  # If email param is provided, looks up user by email (no auth required)
  # If no email param, uses current_user (auth required)
  def primary
    if params[:email].present?
      # External lookup by email (no authentication required)
      user = User.find_by(email: params[:email])
      return render json: { error: "User not found" }, status: :not_found unless user
    else
      # Authenticated user lookup
      user = current_user
    end

    calendar = user.calendars.find_by(is_primary: true)
    
    if calendar
      render json: {
        id: calendar.id,
        name: calendar.name,
        public_token: calendar.public_token,
        public_url: "#{ENV['FRONTEND_URL']}calendar/#{calendar.public_token}",
        timezone: calendar.timezone,
        is_primary: calendar.is_primary,
        created_at: calendar.created_at
      }
    else
      render json: { error: "No primary calendar found" }, status: :not_found
    end
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

    render json: {
      calendar_name: @calendar.name,
      timezone: @calendar.user.timezone || "UTC",
      date: date.to_s,
      slots: slots,
      settings: {
        slot_duration_minutes: @calendar.slot_duration_minutes,
        buffer_minutes: @calendar.buffer_minutes,
        min_advance_hours: @calendar.min_advance_hours,
        max_advance_days: @calendar.max_advance_days
      }
    }
  end

  # GET /calendars/public/:token/availability?date=YYYY-MM-DD
  # Public endpoint - no authentication required
  def public_availability
    calendar = find_and_validate_public_token!(params[:token])
    date = params[:date].presence || Date.current

    slots = CalendarAvailability.new(calendar, date).slots

    render json: {
      calendar_name: calendar.name,
      timezone: calendar.user.timezone || "UTC",
      date: date.to_s,
      slots: slots,
      token_expires_at: calendar.public_token_expires_at,
      token_expiring_soon: calendar.public_token_expiring_soon?
    }
  end

  # DELETE /calendars/public/:token/events/last
  # Public endpoint - no authentication required
  # Deletes the most recent event for testing purposes
  def public_delete_last_event
    calendar = find_and_validate_public_token!(params[:token])

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
    calendar = find_and_validate_public_token!(params[:token])

    # Find or create client
    client = find_or_create_client(calendar.user, public_event_params[:client])

    # Parse times in user's timezone
    user_timezone = calendar.user.timezone || "UTC"
    start_time = parse_time_in_timezone(public_event_params[:start_time], user_timezone)
    end_time = parse_time_in_timezone(public_event_params[:end_time], user_timezone)

    # Create event
    event = calendar.events.build(
      client: client,
      title: public_event_params[:title],
      description: public_event_params[:description],
      start_time: start_time,
      end_time: end_time
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

  # POST /calendars/:id/regenerate_token
  # Regenerates the public token with a new expiry date
  def regenerate_token
    expiry_days = params[:expiry_days]&.to_i || Calendar::DEFAULT_TOKEN_EXPIRY_DAYS

    if @calendar.regenerate_public_token!(expiry_days: expiry_days)
      render json: {
        success: true,
        message: "Public token regenerated successfully",
        calendar: {
          id: @calendar.id,
          name: @calendar.name,
          public_token: @calendar.public_token,
          public_token_expires_at: @calendar.public_token_expires_at
        }
      }
    else
      render json: { error: "Failed to regenerate token" }, status: :unprocessable_entity
    end
  end

  # POST /calendars/:id/revoke_token
  # Revokes the current public token
  def revoke_token
    @calendar.revoke_public_token!
    render json: {
      success: true,
      message: "Public token revoked successfully"
    }
  end

  # POST /calendars/:id/extend_token
  # Extends the expiry date of the current token
  def extend_token
    additional_days = params[:additional_days]&.to_i || Calendar::DEFAULT_TOKEN_EXPIRY_DAYS

    if @calendar.extend_public_token!(additional_days: additional_days)
      render json: {
        success: true,
        message: "Token expiry extended successfully",
        new_expires_at: @calendar.public_token_expires_at,
        days_until_expiry: @calendar.days_until_token_expires
      }
    else
      render json: { error: "Failed to extend token" }, status: :unprocessable_entity
    end
  end

  # GET /calendars/:id/token_stats
  # Returns analytics and statistics about the public token
  def token_stats
    render json: @calendar.public_token_stats
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

  def parse_time_in_timezone(time_string, timezone)
    return nil if time_string.blank?
    
    # Parse the time string in the user's timezone and convert to UTC
    Time.use_zone(timezone) do
      Time.zone.parse(time_string)
    end
  end

  def set_calendar
    @calendar = current_user.calendars.find(params[:id])
  end

  def calendar_params
    params.require(:calendar).permit(
      :name, 
      :is_primary,
      :slot_duration_minutes,
      :buffer_minutes,
      :min_advance_hours,
      :max_advance_days,
      working_hours: {}
    )
  end
end
