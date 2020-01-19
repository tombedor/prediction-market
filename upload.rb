BUCKET = "gs://partjamsdotbiz-election-data/"
require 'csv'


load '538_parser.rb'
load 'predictit_parser.rb'

five_thirty_eight = CSV.parse(File.read("data/538_output_2020-01-19.csv"), headers:true)
predictit = CSV.parse(File.read("data/predictit_output_2020-01-19.csv"), headers: true)


CSV.open("data/combined_#{Date.today}.csv", "w") do |csv|
	HEADERS = %w(date state candidate predictit_yes predictit_no 538_yes 538_no)
	csv << HEADERS
	predictit.each do |prow|
		match_keys = %w(candidate date state)
		frow = five_thirty_eight.find{|f| f.values_at(*match_keys) == prow.values_at(*match_keys)}
		next if frow.nil?
		csv << [prow['date'], prow['state'], prow['candidate'], prow['yes_price'], prow['no_price'], frow['yes_price'], frow['no_price']]
		
	end
end

%x(gsutil cp data/* #{BUCKET})
