require "tourmaline"
require "dotenv"
require "option_parser"
require "json"

puts "Starting Teledream Bot ..."

config_file = "config.json"

OptionParser.parse do |parser|
  parser.on("-c config.json", "--config=config.json", "Specifies the config file") { |name| config_file = name }
end

keys = Hash(String, String).from_json(File.read(config_file))

module Teledream
  VERSION = "0.1.0"

  class TeledreamBot < Tourmaline::Client
    setter allowed_users : Array(String) = [] of String

    private def user_allowed?(user : User) : Bool
      return true

      unless @allowed_users.size == 0
        return @allowed_users.includes?(user.id.to_s)
      else
        return true
      end
    end

#    private def get_dir(message: String) : String
#
#    end

    private def get_ai_resp(message) : String
      msg = message.text
      if msg.nil?
        return "No valid prompt"

      else
        command = "/home/pim/.conda/envs/ldm/bin/python /home/pim/cSD/stable-diffusion/optimizedSD/optimized_txt2img.py --turbo --H 512 --W 768 --n_iter 1 --n_samples 4 --ddim_steps 50 --prompt \""+msg+"\""
#        File.open("/tmp/teledream.lock", "w") do |file|
#            file.print message
#        end

        Process.run("sh", {"-c", command}) do |proc|
            puts proc.output.gets
#            File.delete("/tmp/teledream.lock")
        end

        lastdirpart = msg.gsub('|','_').gsub(' ','_').gsub(':','_')[0..150]
        sample_path = File.join(["/home/pim/cSD/stable-diffusion/outputs/txt2img-samples", lastdirpart  ])
        p sample_path

        #sample_path = os.path.join(outpath, "_".join(re.split(":| ", prompts[0])))[:150]

        media_group = [] of InputMediaPhoto

        d = Dir.new(sample_path)
        d.each_child { |filename|
          p filename
          fullpath = File.expand_path(filename, sample_path)
          newfile = InputMediaPhoto.new(
            media: fullpath,
            caption: "Local"
          )
          media_group << newfile
        }

        message.reply_with_media_group(media_group)

        return "Done dreaming..."
      end
    end

    @[Command("echo")]
    def echo_command(ctx)
      ctx.message.reply(ctx.text)
    end

    @[On(:message)]
    def on_message(update)
      return unless message = update.message

#      if File.exists?("/tmp/teledream.lock")
#        content = File.open("/tmp/teledream.lock") do |file|
#          file.gets_to_end
#        end
#        return "Busy with: " + content
#      end

      puts "#{message.message_id}: Message recieved: #{message.text}"

      from = message.from
      if from.nil?
        puts "#{message.message_id}: No user id"
        return
      elsif message.text.nil?
        puts "#{message.message_id}: Empty message"
        return
      elsif !user_allowed?(from)
        puts "#{message.message_id}: User not allowed: #{from.first_name} (#{from.id})"
        return
      end

      ai_response = get_ai_resp(message)
      puts "#{message.message_id}: Message reply: #{ai_response}"
      message.reply(ai_response, parse_mode: ParseMode::HTML)
    end
  end

  bot = TeledreamBot.new(bot_token: keys["TELEGRAM_BOT_KEY"])
  bot.allowed_users = keys["ALLOWED_USERS"].split(",") if keys.keys.includes? "ALLOWED_USERS"
  bot.poll
end
