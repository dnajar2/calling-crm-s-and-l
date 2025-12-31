class EventNotesController < ApplicationController
  before_action :set_event
  before_action :set_event_note, only: [ :show, :update, :destroy ]

  # GET /events/:event_id/event_notes
  def index
    event_notes = @event.event_notes.ordered_by_occurred_at
    render json: event_notes
  end

  # POST /events/:event_id/event_notes
  def create
    event_note = @event.event_notes.build(event_note_params)
    event_note.user = current_user

    if event_note.save
      render json: event_note, status: :created
    else
      render json: { errors: event_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /events/:event_id/event_notes/:id
  def show
    render json: @event_note
  end

  # PATCH /events/:event_id/event_notes/:id
  def update
    if @event_note.update(event_note_params)
      render json: @event_note
    else
      render json: { errors: @event_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /events/:event_id/event_notes/:id
  def destroy
    @event_note.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.joins(calendar: :user)
                  .where(calendars: { user_id: current_user.id })
                  .find(params[:event_id])
  end

  def set_event_note
    @event_note = @event.event_notes.find(params[:id])
  end

  def event_note_params
    params.require(:event_note).permit(
      :content,
      :visible_to_client,
      :follow_up_required,
      :occurred_at
    )
  end
end
