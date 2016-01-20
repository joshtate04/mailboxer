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

    send_sms

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

    send_sms(receiver, order)

    set_subject(message)
    mail :to => receiver.send(Mailboxer.email_method, message),
         :subject => t('mailboxer.message_mailer.subject_reply', :subject => @subject),
         :template_name => 'reply_message_email'
  end

  private

  def send_sms(receiver, order, link)
    if receiver.is_a? Order
      phone_numbers = [order.order_transaction.user.phone]
    else
      phone_numbers = order.restaurant_location.phones.map(&:phone)
    end
    title = "[Platterz] Order #{order.order_number}\n\n"
    message = "#{message.truncate(100)}\n\n"
    footer = "Respond here: #{link}"

    msg_body = "#{title}#{message}#{footer}"

    SmsDeviceService.get_instance.send_sms_to_single_number(msg_body, phone_numbers)
  end
end
