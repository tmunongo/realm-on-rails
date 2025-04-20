# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  def not_found
    # Optional: Log the missing page URL
    # Rails.logger.warn "404 Not Found: #{request.original_url}"

    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: "Not Found" }, status: :not_found }
      format.any { head :not_found }
    end
  end
end
