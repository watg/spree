object @suite
attributes *suite_attributes
child :image => :image do
  node("mobile_url") { |i| i.attachment.url(:mobile) }
end
