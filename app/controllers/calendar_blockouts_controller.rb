class CalendarBlockoutsController < ApplicationController
  before_action :set_calendar
  before_action :set_blockout, only: [:show, :update, :destroy]

  # GET /calendars/:calendar_id/blockouts
  def index
    blockouts = @calendar.blockouts.order(start_date: :asc)
    render json: blockouts
  end

  # GET /calendars/:calendar_id/blockouts/:id
  def show
    render json: @blockout
  end

  # POST /calendars/:calendar_id/blockouts
  def create
    blockout = @calendar.blockouts.build(blockout_params)

    if blockout.save
      render json: blockout, status: :created
    else
      render json: { errors: blockout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /calendars/:calendar_id/blockouts/:id
  def update
    if @blockout.update(blockout_params)
      render json: @blockout
    else
      render json: { errors: @blockout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /calendars/:calendar_id/blockouts/:id
  def destroy
    @blockout.destroy
    head :no_content
  end

  private

  def set_calendar
    @calendar = current_user.calendars.find(params[:calendar_id])
  end

  def set_blockout
    @blockout = @calendar.blockouts.find(params[:id])
  end

  def blockout_params
    params.require(:blockout).permit(:start_date, :end_date, :reason, :recurring)
  end
end
