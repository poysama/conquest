class User < ActiveRecord::Base
  TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/
  # Use friendly_id on Users
  extend FriendlyId
  friendly_id :friendify, use: :slugged

  # necessary to override friendly_id reserved words
  def friendify
    if username.downcase == "admin"
      "user-#{username}"
    else
      "#{username}"
    end
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # Pagination
  paginates_per 100

  # Validations
  # :username
  validates :username, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /\A[a-zA-Z0-9]*\z/, on: :create, message: "can only contain letters and digits"
  validates :username, length: { in: 4..25 }
  # :email
  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  def self.paged(page_number)
    order(admin: :desc, username: :asc).page page_number
  end

  def self.search_and_order(search, page_number)
    if search
      where("username LIKE ?", "%#{search.downcase}%").order(
      admin: :desc, username: :asc
      ).page page_number
    else
      order(admin: :desc, username: :asc).page page_number
    end
  end

  def self.last_signups(count)
    order(created_at: :desc).limit(count).select("id","username","slug","created_at")
  end

  def self.last_signins(count)
    order(last_sign_in_at:
    :desc).limit(count).select("id","username","slug","last_sign_in_at")
  end

  def self.users_count
    where("admin = ? AND locked = ?",false,false).count
  end

  def self.find_for_oauth(auth, signed_in_resource = nil)

    # Get the identity and user if they exist
    identity = Identity.find_for_oauth(auth)

    # If a signed_in_resource is provided it always overrides the existing user
    # to prevent the identity being locked with accidentally created accounts.
    # Note that this may leave zombie accounts (with no associated identity) which
    # can be cleaned up at a later date.
    user = signed_in_resource ? signed_in_resource : identity.user

    # Create the user if needed
    if user.nil?

      # Get the existing user by email if the provider gives us a verified email.
      # If no verified email was provided we assign a temporary email and ask the
      # user to verify it on the next step via UsersController.finish_signup
      email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if email_is_verified
      user = User.where(:email => email).first if email

      # Create the user if it's a new registration
      if user.nil?
        user = User.new(
          name: auth.extra.raw_info.name,
          username: auth.info.nickname || auth.uid,
          email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
          password: Devise.friendly_token[0,20]
        )
        p user.username
        user.skip_confirmation!
        user.save!
      end
    end

    # Associate the identity with the user if needed
    if identity.user != user
      identity.user = user
      identity.save!
    end
    user
  end

  def email_verified?
    self.email && self.email !~ TEMP_EMAIL_REGEX
  end
end
