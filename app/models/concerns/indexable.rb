module Indexable
  extend ActiveSupport::Concern
  included do
    def index_elasticsearch
      ElasticsearchJob.perform_later(self.class.to_s, id)
      self
    end
  end
end