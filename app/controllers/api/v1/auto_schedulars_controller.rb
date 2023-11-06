class Api::V1::AutoSchedularsController < Api::V1::ApiController

  before_action :authenticate_active_user, except: [:data]
  
  def data
  end

end