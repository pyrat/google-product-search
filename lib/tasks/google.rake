raw_config = File.read(RAILS_ROOT + "/config/google_base.yml")
BASE_CONFIG = YAML.load(raw_config)

namespace :googlebase do
  
  desc "Generate a google sitemap to public/google_base.xml"
  task :generate => :environment do
    results = '<?xml version="1.0"?>' + "\n" + '<rss version="2.0" xmlns:g="http://base.google.com/ns/1.0">' + "\n" + _filter_xml(_build_xml) + '</rss>'
    File.open("#{RAILS_ROOT}/public/google_base.xml", "w") do |io|
      io.puts(results)
    end
  end
  
end

def _get_product_type(product)
  "Media > Maps"
end

def _filter_xml(output)
  fields = ['price', 'brand', 'condition', 'image_link', 'product_type', 'id', 'quantity', 'mpn']
  fields.each do |field|
    output = output.gsub(field + '>', 'g:' + field + '>') 
  end
  output
end

def _build_xml
  returning '' do |output|
    @public_dir = BASE_CONFIG['public_domain'] || ''
    xml = Builder::XmlMarkup.new(:target => output, :indent => 2, :margin => 1)
    xml.channel {
      xml.title BASE_CONFIG['google_base_title'] || ''
      xml.link @public_dir
      xml.description BASE_CONFIG['google_base_desc'] || ''
      Product.live.each do |product|
        xml.item {
          xml.id product.id.to_s
          xml.title product.title
          xml.link @public_dir + '/products/' + product.friendly_id
          xml.description CGI.escapeHTML(product.description)
          xml.price product.price
          xml.condition 'new'
          xml.image_link @public_dir.sub(/\/$/, '') + product.featured_photo.public_filename
          xml.product_type _get_product_type(product)
        }
      end
    }
  end
end
