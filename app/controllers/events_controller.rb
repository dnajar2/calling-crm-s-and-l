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
