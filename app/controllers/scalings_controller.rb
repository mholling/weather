class ScalingsController < ApplicationController
  def index
    @scalings = Scaling.scoped({})
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def update
    # Rails.logger.info "got params:\n#{params.inspect}\n"
    @scaling = Scaling.find(params[:id]).update_attributes(:position => params[:position])
    render :nothing => true
  end
end
