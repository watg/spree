class UniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if Video.where(Hash[attribute,value]).count > 0
      record.errors[attribute] << 'already exists'
    end
  end
end