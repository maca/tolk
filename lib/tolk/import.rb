module Tolk
  module Import
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def import_secondary_locales
        locales = Dir.entries(self.locales_config_path)

        locale_block_filter = Proc.new {
          |l| ['.', '..'].include?(l) ||
            !l.ends_with?('.yml') ||
            l.match(/(.*\.){2,}/) # reject files of type xxx.en.yml
        }
        locales = locales.reject(&locale_block_filter).map {|x| x.split('.').first }
        locales = locales + Tolk.config.additional_locales - [Tolk::Locale.primary_locale.name]
        locales.each {|l| import_locale(l) }
      end

      def import_locale(locale_name)
        locale = Tolk::Locale.where(name: locale_name).first_or_create
        data = I18n.backend.send(:translations)[locale_name.to_sym]
        return unless data

        phrases = Tolk::Phrase.all
        count = 0

        data.each do |key, value|
          phrase = phrases.detect {|p| p.key == key}

          if phrase
            translation = locale.translations.new(:text => value, :phrase => phrase)
            if translation.save
              count = count + 1
            elsif translation.errors[:variables].present?
              puts "[WARN] Key '#{key}' from '#{locale_name}.yml' could not be saved: #{translation.errors[:variables].first}"
            end
          else
            puts "[ERROR] Key '#{key}' was found in '#{locale_name}.yml' but #{Tolk::Locale.primary_language_name} translation is missing"
          end
        end

        puts "[INFO] Imported #{count} keys from #{locale_name}.yml"
      end

    end

  end
end
