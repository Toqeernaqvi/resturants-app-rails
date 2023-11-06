class ElasticsearchJob < ApplicationJob
  queue_as :elasticsearch_reindex

  def perform(clazz, id)
    puts "Indexing #{clazz} id #{id}"
    clazz.constantize.find(id).reindex
  end
end
