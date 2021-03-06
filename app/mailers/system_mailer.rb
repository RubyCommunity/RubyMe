# Sends admin mail for system events
class SystemMailer < ActionMailer::Base
  default from: Settings.site_mailer.from, return_path: Settings.site_mailer.return_path

  def welcome_mail(params)
    @send_to = params["send_to"]

    mail(to: @send_to, subject: "RubyMe 欢迎你") do |format|
      format.html { render "mailers/system_mailer/welcome_register", layout: false }
    end
  end

  def sensitive_mail(params)
    @send_to = params["send_to"]
    @content = params["content"]

    mail(to: @send_to, subject: "RubyMe敏感词检测结果") do |format|
      format.html { render "mailers/system_mailer/page_sensitive", layout: false }
    end
  end
end
