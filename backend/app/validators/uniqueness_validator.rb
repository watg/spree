class UniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    video = Video.where(Hash[attribute,value]).first
    if exists?(record, video)
      record.errors[attribute] << 'already exists'
    end
  end

  def exists?(record, video)
    if record.respond_to?(:id) 
      video && (video.id != record.id.to_i) 
    else 
      video
    end
  end
end