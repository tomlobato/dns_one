require "spec_helper"
require 'resolv'

# Run this before 'rake test':
# ruby -Ilib/ exe/dns_one run --conf spec/test_conf.yml

IN = Resolv::DNS::Resource::IN

def dom_resolv? dom, type_class = IN::A
	@dns_resolver ||= Resolv::DNS.new(
	  :nameserver =>       	['127.0.0.1'],
	  :nameserver_port =>	[['127.0.0.1', 10153]],
	  :search => 			[''],
	  :ndots => 			1
	)

	puts "resolving #{dom} #{type_class.to_s.split('::').last}"

	result = @dns_resolver.getresource dom, type_class

	return unless result

	val = case type_class.to_s

		when IN::A.to_s, IN::AAAA.to_s
			result.address.to_s.downcase

		when IN::SOA.to_s
			%w(mname rname serial refresh retry expire minimum).map{|field| result.send field }.join " "

		when IN::NS.to_s, IN::CNAME.to_s
			result.name.to_s.downcase

		else
			raise "unsupported type #{type_class}"
		end

	[
		val, 
		result.class
	]
end

RSpec.describe DnsOne do
	it "has a version number" do
		expect(DnsOne::VERSION).not_to be nil
	end
	it "resolves domains from file backend" do
		[
			[ %w( dom1.com 216.58.210.238
				  dom2.com 216.58.210.237
				  dom3.com 216.58.210.238
				  dom4.com 216.58.210.237 ),
			  IN::A
			],
			[ %w( dom1.com 2a00:1450:4006:803::200f
				  dom2.com 2a00:1450:4006:803::200e
				  dom3.com 2a00:1450:4006:803::200f
				  dom4.com 2a00:1450:4006:803::200e ),
			  IN::AAAA
			],
			[ %w( dom1.com ns1.mynsserver.com.
				  dom2.com ns1.myothernsserver.com.
				  dom3.com ns1.mynsserver.com.
				  dom4.com ns1.myothernsserver.com. ),
			  IN::NS
			],
			[ ["dom1.com", "ns1.mynsserver.com. www.mycompany.com. 2016042600 900 600 300 200",
			  "dom2.com", "ns1.myotherserver.com. www.myothercompany.com. 2016042601 900 600 300 100",
			  "dom3.com", "ns1.mynsserver.com. www.mycompany.com. 2016042600 900 600 300 200",
			  "dom4.com", "ns1.myotherserver.com. www.myothercompany.com. 2016042601 900 600 300 100"],
			  IN::SOA
			]
		].each do |test|
			dom_list, type_class = test
			Hash[*dom_list].each_pair do |dom, resp|
				res = dom_resolv? dom, type_class
				expect(res).to eq([resp.downcase, type_class])
			end
		end
	end
end
