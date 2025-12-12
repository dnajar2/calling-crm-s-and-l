class AiController < ApplicationController
  def chat
    query = params[:query].to_s
    result = Ai::AiAssistant.new(query, current_user).run
    render json: result
  end
end
