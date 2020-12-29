require 'kimurai'

class KingstonGreenDirectoryScraper < Kimurai::Base
  def self.full_url(path)
    ROOT_PATH + path
  end

  @name = "kingston_edirectory_spider"
  @engine = :mechanize
  ROOT_PATH = "https://e-voice.org.uk/kingstongreendirectory"
  @start_urls = [
    full_url("/business-2-business"),
    full_url("/education"),
    full_url("/energy"),
    full_url("/food-and-drink"),
    full_url("/homes"),
    full_url("/gardens"),
    full_url("/professional-services"),
    full_url("/retail"),
    full_url("/transport-and-travel"),
  ]
  @config = {}

  def parse(response, url:, data: {})
    main = response.css('.main-content')
    item = init_item
    next_item_valid = true
    main.css('p').each do |node|
      if next_item_valid
        patterns = [
          'strong span[@style*="color: #008000;"]',
          'span[@style*="color: #008000;"] > strong',
          'span[@style*="font-family: verdana"] > strong > span[@style="color: #008000;"]',
          'strong[@style="color: #008000;"]'
        ]
        name_node = []
        patterns.each do |pattern|
          # puts "Checking pattern #{pattern}"
          name_node = node.css(pattern)
          break unless name_node.empty?
        end
        if name_node.any?

          save_item(item)
          item = init_item

          name = name_node[0].content
          next if name == name.upcase
          puts '------------------------------------'
          puts 'name'
          puts name
          item[:name] = name

          item[:address] = node.css('span[@style="color: #008000;"]')[1]

          next_item_valid = false
        end
      end

      # puts node.content
      content = node.content
      labels = {
        about: 'About us:',
        awards: 'Green awards and accreditations:',
        ttk_comment: 'TTK comment:',
        phone: 'Phone:',
        url: 'Website:',
        email: 'Email:',
      }
      labels.each_pair do |key, label|
        if content.start_with?(label)
          item[key] = content.strip.delete_prefix(label).strip
          puts key
          puts item[key]

          next_item_valid = [:url, :email].include?(key)
        end        
      end
    end
    save_item(item)
  end

  def save_item(item)
    # puts item
    save_to 'kingston_green_directory.csv', item, format: :csv if item[:name].present?
  end

  def init_item
    {name: '', address: '', awards: '', phone: '', url: '', email: '', about: '', ttk_comment: ''}
  end
end

KingstonGreenDirectoryScraper.crawl!
