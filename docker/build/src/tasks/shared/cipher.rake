# frozen-string-literal: true

require_relative '../../lib/schematic/cipher'

namespace :cipher do
  desc "Generate cipher keys"
  task :generate_keys do
    Schematic::Cipher.new.generate_keys
  end

  desc "Encrypt a string"
  task :encrypt, [:string] do |_, args|
    string = args.string
    if string.nil?
      require 'io/console'
      puts "Enter text to encrypt"
      string = STDIN.noecho(&:gets).chomp
    end
    puts Schematic::Cipher.new.encrypt(string)
  end

  desc "Encrypt an environment variable"
  task :encrypt_env_var, [:env_var] do |_, args|
    puts Schematic::Cipher.new.encrypt_env_var(args.env_var)
  end

  desc "Decrypt an environment variable"
  task :decrypt_env_var, [:env_var] do |_, args|
    puts Schematic::Cipher.new.decrypt_env_var(args.env_var)
  end
end
