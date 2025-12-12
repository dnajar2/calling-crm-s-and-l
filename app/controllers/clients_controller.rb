class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :update, :destroy ]

  # GET /clients
  def index
    render json: current_user.clients
  end

  # GET /clients/:id
  def show
    render json: @client
  end

  # POST /clients
  def create
    client = current_user.clients.build(client_params)

    if client.save
      render json: client, status: :created
    else
      render json: { errors: client.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /clients/:id
  def update
    if @client.update(client_params)
      render json: @client
    else
      render json: {
        errors: @client.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /clients/:id
  def destroy
    @client.destroy
    head :no_content
  end

  private

  def set_client
    @client = current_user.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :email, :phone)
  end
end
