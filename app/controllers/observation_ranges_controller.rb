class ObservationRangesController < ApplicationController
  def show
    first = Observation.chronological.first.time
    last = Observation.chronological.last.time
    respond_to do |format|
      format.json { render :json => { "minDate" => first.to_js, "maxDate" => last.to_js } }
    end
  end
end
