# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]

Rails.application.config.filter_parameters += [ :user, :password_digest, :password_confirmation, :new_password, :current_password, :session_token, :token_digest, :cookie ]
Rails.application.config.filter_parameters += [ :authorization ]

Rails.application.config.filter_parameters += [
  :booking, :contact_name, :company, :invoice, :plate, :vehicle_model, :request_id, :release_remark, :change_reason, :reason, :previous_values, :new_values
]
