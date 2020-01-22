BUCKET = "gs://partjamsdotbiz-election-data/"
require 'csv'

keepalive = Thread.new { %x(caffeinate -d) }

load '538_parser.rb'
load 'predictit_parser.rb'

five_thirty_eight = CSV.parse(File.read("data/538_output_#{Date.today}.csv"), headers:true)
predictit = CSV.parse(File.read("data/predictit_output_#{Date.today}.csv"), headers: true)


CSV.open("data/combined_#{Date.today}.csv", "w") do |csv|
	HEADERS = %w(date state candidate predictit_yes predictit_no 538_yes 538_no delta_yes delta_no delta_yes_percent delta_no_percent predictit_url 538_url)
	csv << HEADERS
	predictit.each do |prow|
		match_keys = %w(candidate date state)
		frow = five_thirty_eight.find{|f| f.values_at(*match_keys) == prow.values_at(*match_keys)}
		next if frow.nil?

		date,state,candidate= prow.values_at('date', 'state', 'candidate')
		pyes, pno = prow.values_at('yes_price', 'no_price').map(&:to_f)
		fyes, fno = frow.values_at('yes_price', 'no_price').map(&:to_f)
		delta_yes = pyes - fyes
		delta_no = pno - fno
		delta_yes_percent = delta_yes / pyes
		delta_no_percent = delta_no / pno

		csv << [date, state, candidate, pyes, pno, fyes, fno, delta_yes, delta_no, delta_yes_percent, delta_no_percent, prow['url'], frow['url']]
	end
end

%x(gsutil cp data/* #{BUCKET})
keepalive.kill
