class UniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    video = Video.where(Hash[attribute,value]).first
    if record.respond_to?(:id) && video && (video.id != record.id) || !record.respond_to?(:id) && video
    	record.errors[attribute] << 'already exists'
    end
  end
end