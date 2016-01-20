class Mailboxer::MessageMailer < Mailboxer::BaseMailer
  #Sends and email for indicating a new message or a reply to a receiver.
  #It calls new_message_email if notifing a new message and reply_message_email
  #when indicating a reply to an already created conversation.
  def send_email(message, receiver)
    order = Order.find_by_conversation_id(conversation_id)

    if message.conversation.messages.size > 1
      reply_message_email(message,receiver, order)
    else
      new_message_email(message,receiver, order)
    end
  end

  #Sends an email for indicating a new message for the receiver
  def new_message_email(message,receiver, order)
    @message  = message
    @receiver = receiver

    if @receiver.is_a? Order
      shortened_id = Shortener::ShortenedUrl.generate("www.platterz.ca/#/orders?oi=#{order.id}&on=#{order.order_number}")
      @link = "api.platterz.ca/n/#{shortened_id}"
    elsif @receiver.is_a? User
      shortened_id = Shortener::ShortenedUrl.generate("manage.platterz.ca/#/orders?oi=#{order.id}&on=#{order.order_number}")
      @link = "api.platterz.ca/n/#{shortened_id}"
    else
      return
    end

    Mailboxer::MessageMailer.send_sms(receiver, @link, order)

    set_subject(message)
    mail :to => receiver.send(Mailboxer.email_method, message),
         :subject => t('mailboxer.message_mailer.subject_new', :subject => @subject),
         :template_name => 'new_message_email'
  end

  #Sends and email for indicating a reply in an already created conversation
  def reply_message_email(message,receiver, order)
    @message  = message
    @receiver = receiver

    if @receiver.is_a? Order
      shortened_id = Shortener::ShortenedUrl.generate("www.platterz.ca/#/orders?oi=#{order.id}&on=#{order.order_number}")
      @link = "api.platterz.ca/n/#{shortened_id}"
    elsif @receiver.is_a? User
      shortened_id = Shortener::ShortenedUrl.generate("manage.platterz.ca/#/orders?oi=#{order.id}&on=#{order.order_number}")
      @link = "api.platterz.ca/n/#{shortened_id}"
    else
      return
    end

    Mailboxer::MessageMailer.send_sms(receiver, @link, order)

    set_subject(message)
    mail :to => receiver.send(Mailboxer.email_method, message),
         :subject => t('mailboxer.message_mailer.subject_reply', :subject => @subject),
         :template_name => 'reply_message_email'
  end

  private

  def self.send_sms(receiver, order, link)
    title = "[Platterz] Order #{order.order_number}"
    message = "#{message.truncate(100)}"
    footer = "Respond here: #{link}"
    if receiver.is_a? Order
      SmsDeviceService.get_instance.send_sms_to_single_number(
        [title, message, footer].join("\n\n"),
        receiver.phone)
    else
      SmsDeviceService.get_instance.send_sms_to_phone_list(
        [title, message, footer].join("\n\n"),
        order.restaurant_location.phones)
    end
  end
end
