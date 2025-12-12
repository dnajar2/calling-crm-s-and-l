class NotesController < ApplicationController
  before_action :set_note, only: [ :show, :update, :destroy ]

  # GET /notes
  def index
    notes = current_user.notes.order(created_at: :desc)
    render json: notes
  end

  # GET /notes/:id
  def show
    render json: @note
  end

  # POST /notes
  # Params: { note: { content: "..." } }
  def create
    note = current_user.notes.build(note_params)

    if note.save
      render json: note, status: :created
    else
      render json: { errors: note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /notes/:id
  def update
    if @note.update(note_params)
      render json: @note
    else
      render json: { errors: @note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /notes/:id
  def destroy
    @note.destroy
    head :no_content
  end

  # GET /notes/search?query=...
  def search
    query = params[:query].to_s
    return render json: { notes: [] } if query.blank?

    query_embedding = EmbeddingService.generate(query)
    return render json: { error: "Failed to generate embedding" } unless query_embedding

    notes = current_user.notes.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(5)

    render json: {
      query: query,
      results: notes
    }
  end

  private

  def set_note
    @note = current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
