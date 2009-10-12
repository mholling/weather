class ScalingsController < ApplicationController
  def index
    @scalings = Scaling.scoped(:include => :scale)
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def update
    @scaling = Scaling.find(params[:id]).update_attributes(:position => params[:position])
    render :nothing => true
  end
end
