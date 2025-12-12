class CalendarsController < ApplicationController
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

  private

  def set_calendar
    @calendar = current_user.calendars.find(params[:id])
  end

  def calendar_params
    params.require(:calendar).permit(:name)
  end
end
