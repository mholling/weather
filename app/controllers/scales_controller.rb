class ScalesController < ApplicationController
  def show
    @scale = Scale.find(params[:id])
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
end
