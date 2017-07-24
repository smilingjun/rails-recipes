require 'csv'
class RegistrationImportCsvUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url(*args)
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fit: [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_whitelist
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

     mount_uploader :csv_file, RegistrationImportCsvUploader

   validates_presence_of :csv_file

   belongs_to :event
   belongs_to :user

   serialize :error_messages, JSON

   def process!
     csv_string = self.csv_file.read.force_encoding('utf-8')
     tickets = self.event.tickets

     success = 0
     failed_records = []

     CSV.parse(csv_string) do |row|
       registration = self.event.registrations.new( :status => "confirmed",
                                    :ticket => tickets.find{ |t| t.name == row[0] },
                                    :name => row[1],
                                    :email => row[2],
                                    :cellphone => row[3],
                                    :website => row[4],
                                    :bio => row[5],
                                    :created_at => Time.parse(row[6]) )

       if registration.save
         success = 1
       else
         failed_records << [row, registration.errors.full_messages]
       end
     end

     self.status = "imported"
     self.success_count = success
     self.total_count = success  failed_records.size
     self.error_messages = failed_records

     self.save!
   end

end
