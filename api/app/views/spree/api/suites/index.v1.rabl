object false
# node(:count) { @suites.count }
# node(:total_count) { @suites.total_count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
# node(:pages) { @suites.num_pages }

child(@suites => :suites) do
  extends "spree/api/suites/show"
end
