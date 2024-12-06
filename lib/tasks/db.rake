namespace :db do
  namespace :seed do
    desc "Dump default settings as seed data to db/seeds/*.rb"
    task export: :environment do
      seeds_path = Pathname.new(Rails.application.paths["db"].first) / 'seeds'
      (seeds_path / 'templates').glob('*.erb').each do |template_path|
        template = ERB.new(template_path.read, trim_mode: '<>')
        (seeds_path / "#{template_path.basename('.*').to_s}.rb").write(template.result)
      end
    end
  end
end
