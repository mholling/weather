class ObservationRangesController < ApplicationController
  def show
    first = Observation.chronological.first.time
    last = Observation.chronological.last.time
    respond_to do |format|
      format.json { render :json => { "minDate" => first.to_i*1000, "maxDate" => last.to_i*1000 } }
    end
  end
end
