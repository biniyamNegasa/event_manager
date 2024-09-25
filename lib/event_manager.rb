require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(phone_number)
  digits_only = []
  phone_number.each_char do |ch|
    if '0'.ord <= ch.ord && ch.ord <= '9'.ord
      digits_only << ch
    end
  end
  length = digits_only.length
  if length == 10 || (length == 11 && digits_only[0] == '1')
    digits_only.join()[-10..-1]
  else
    'bad'
  end

end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )
    legislators = legislators.officials
    legislators = legislators.map(&:name).join(', ')
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thankyou_letter(id, personal_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts personal_letter
  end
end
puts 'EventManager initialized.'

template_file = File.read('form_letter.erb')
erb_template = ERB.new template_file
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  personal_letter = erb_template.result(binding)
  # puts "#{name} #{zipcode} #{legislators}"
  puts clean_phone_numbers(row[:homephone])
  save_thankyou_letter(id, personal_letter)
end
