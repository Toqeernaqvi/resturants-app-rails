module Onfleet
  class Team < OnfleetObject
    include Onfleet::Actions::List
    include Onfleet::Actions::Get
    include Onfleet::Actions::Create
    include Onfleet::Actions::Save

    def self.api_url
      '/teams'
    end
  end
end
