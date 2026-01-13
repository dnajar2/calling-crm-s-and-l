class EventsController < ApplicationController
  before_action :set_event, only: [ :show, :update, :destroy ]
  before_action :set_calendar, only: [ :index, :create ]

  # GET /calendars/:calendar_id/events
  def index
    events = @calendar.events.includes(:client)
    render json: events
  end

  # POST /calendars/:calendar_id/events
  def create
    event = @calendar.events.build(event_params)

    if event.save
      render json: event, status: :created
    else
      render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /events/:id
  def show
    render json: @event
  end

  # PATCH /events/:id
  def update
    if @event.update(event_params)
      render json: @event
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /events/:id
  def destroy
    @event.destroy
    head :no_content
  end

  # GET /events/dashboard
  # Returns dashboard statistics
  def dashboard
    user_tz = current_user.timezone || 'UTC'
    tz = ActiveSupport::TimeZone[user_tz]
    now = tz.now
    
    today_start = now.beginning_of_day
    today_end = now.end_of_day
    week_start = now.beginning_of_week
    week_end = now.end_of_week
    
    # Get all user events
    user_events = Event.joins(calendar: :user)
                      .where(calendars: { user_id: current_user.id })
    
    # Calculate counts
    today_count = user_events.where(start_time: today_start..today_end).count
    week_count = user_events.where(start_time: week_start..week_end).count
    total_clients = current_user.clients.count
    
    # Calculate growth (events this week vs last week)
    last_week_start = week_start - 1.week
    last_week_end = week_end - 1.week
    last_week_count = user_events.where(start_time: last_week_start..last_week_end).count
    
    growth_percentage = if last_week_count > 0
      ((week_count - last_week_count).to_f / last_week_count * 100).round
    else
      week_count > 0 ? 100 : 0
    end
    
    render json: {
      today_events: today_count,
      this_week_events: week_count,
      total_clients: total_clients,
      growth_percentage: growth_percentage
    }
  end

  # GET /events/today
  # Returns today's events in schedule format
  def today
    user_tz = current_user.timezone || 'UTC'
    tz = ActiveSupport::TimeZone[user_tz]
    now = tz.now
    
    today_start = now.beginning_of_day
    today_end = now.end_of_day
    
    events = Event.joins(calendar: :user)
                  .includes(:client)
                  .where(calendars: { user_id: current_user.id })
                  .where(start_time: today_start..today_end)
                  .order(:start_time)
    
    formatted_events = events.map do |event|
      start_in_tz = event.start_time.in_time_zone(user_tz)
      end_in_tz = event.end_time.in_time_zone(user_tz)
      
      {
        id: event.id,
        title: event.title,
        description: event.description,
        client_name: event.client.name,
        start_time: start_in_tz.iso8601,
        end_time: end_in_tz.iso8601,
        start_time_formatted: start_in_tz.strftime('%I:%M %p'),
        end_time_formatted: end_in_tz.strftime('%I:%M %p'),
        time_range: "#{start_in_tz.strftime('%I:%M %p')} - #{end_in_tz.strftime('%I:%M %p')}"
      }
    end
    
    render json: {
      date: now.strftime('%A, %B %d, %Y'),
      timezone: user_tz,
      events: formatted_events
    }
  end

  # GET /events/upcoming
  # Returns upcoming events (future events)
  def upcoming
    user_tz = current_user.timezone || 'UTC'
    tz = ActiveSupport::TimeZone[user_tz]
    now = tz.now
    
    events = Event.joins(calendar: :user)
                  .includes(:client)
                  .where(calendars: { user_id: current_user.id })
                  .where('start_time > ?', now)
                  .order(:start_time)
                  .limit(10)
    
    formatted_events = events.map do |event|
      start_in_tz = event.start_time.in_time_zone(user_tz)
      end_in_tz = event.end_time.in_time_zone(user_tz)
      
      # Determine relative time label
      days_until = (start_in_tz.to_date - now.to_date).to_i
      relative_label = case days_until
      when 0
        "Today"
      when 1
        "Tomorrow"
      else
        start_in_tz.strftime('%b %d, %Y')
      end
      
      {
        id: event.id,
        title: event.title,
        description: event.description,
        client_name: event.client.name,
        start_time: start_in_tz.iso8601,
        end_time: end_in_tz.iso8601,
        date_label: start_in_tz.strftime('%b'),
        day_label: start_in_tz.strftime('%d'),
        time_label: start_in_tz.strftime('%I:%M %p'),
        relative_label: relative_label,
        full_date_time: "#{relative_label} • #{start_in_tz.strftime('%I:%M %p')}"
      }
    end
    
    render json: {
      timezone: user_tz,
      events: formatted_events
    }
  end

  private

  def set_calendar
    @calendar = current_user.calendars.find(params[:calendar_id])
  end

  def set_event
    @event = Event.joins(calendar: :user)
                  .where(calendars: { user_id: current_user.id })
                  .find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :start_time,
      :end_time,
      :client_id,
      :title,
      :description
    )
  end
end
