module Metapack
  class Client
    def create_and_allocate_consignment(consignment)
      url = Metapack::Config.service_base_url + "/allocationService"
      Net::HTTP.start(Metapack::Config.host) {|http|
        req = Net::HTTP::Post.new(url)
        req.basic_auth Metapack::Config.username, Metapack::Config.password
        http.request(req)
      }
    end
  end
end
