# encoding: utf-8
require 'open-uri'
require 'file_size_validator'
class User < ActiveRecord::Base
  include LetterAvatar::AvatarHelper

  extend FriendlyId
  friendly_id :uid, use: :finders

  mount_uploader :avatar, UserAvatarUploader

  #Association
  has_many :messages, dependent: :destroy, foreign_key: :user_id
  has_many :posts, dependent: :destroy
  has_many :codes, dependent: :destroy
  has_many :blogs, dependent: :destroy
  has_many :replies, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_one :postgresql_search, as: :searchable


  #Callback
  before_create :update_ranking
  before_create :init_name, if: Proc.new { |u| u.name.blank? }
  after_create :init_avatar
  after_create :send_welcome_mail
  after_create :create_default_category

  attr_accessor :login

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable, :timeoutable,
         :recoverable, :rememberable, :trackable, :validatable, :async,
         authentication_keys: [:login]

  #Validate
  validates :ranking, uniqueness: true
  validates :city_name, allow_blank: true, length: {minimum: 2}
  validates :avatar, file_size: {maximum: 1.megabytes.to_i}, on: [:update] #, if: Proc.new { |u| u.avatar_changed? }

  validates :uid, presence: true, allow_blank: false, uniqueness: {case_sensitive: true},
            length: {minimum: 3, maximum: 24}, exclusion: {in: Settings.exclusions},
            :format => {:with => /\A\w+\z/, :message => '只允许数字、大小写字母和下划线'}
  # validates :avatar, presence: true, file_size: {
  #   minimum: 3.kilobytes.to_i, maximum: 1.megabytes.to_i }
  validates :email, presence: true, allow_blank: false, uniqueness: {case_sensitive: false},
            format: {with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i, message: 'Email格式不正确'}

  class << self
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).where(["uid = :value OR email = :value", {value: login}]).first
      else
        where(conditions).first
      end
    end
  end

  after_save :update_index
  def update_index
    if true
      SearchIndexerWorker.perform_async('user', self.id)
    end
  end

  def to_search_data
    "#{self.login} #{self.name}"
  end

  def human_name
    self.uid
  end

  def whose_blogger
    "#{self.uid} 的博客"
  end

  def created_time
    self.created_at.strftime('%Y-%m-%d %H:%M')
  end

  def github_page
    "https://github.com/#{self.github}"
  end

  def city
    self.city_name.blank? ? '未知' : self.city_name
  end

  def blogger_title
    self.signature.blank? ? self.whose_blogger : self.signature
  end

  def avatar_url(size, version=nil)
    if self.avatar? && self.avatar.versions.keys.include?(version.try(:to_sym))
      self.avatar.send(version).url
    else
      width = user_avatar_width_for_size(size)
      self.letter_avatar_url(width * 2)
    end
  end


  def letter_avatar_url(size)
    path = LetterAvatar.generate(self.name, size).sub('public/', '/')

    "//#{Settings.site.domain}:#{Settings.site.port}#{path}"
  end

  def user_avatar_width_for_size(size)
    case size
      when :normal then 48
      when :small then 16
      when :large then 96
      when :big then 120
      else size
    end
  end

  def email_md5
    Digest::MD5.hexdigest(self.email.downcase)
  end

  def gravatar_url #blocked in ZH
    "http://www.gravatar.com/avatar/#{self.email_md5}"
  end

  private
  def update_ranking
    # debugger
    current_ranking = User.maximum(:ranking).to_i
    self.ranking = current_ranking + 1
  end


  def init_name
    self.name = self.uid
  end

  def init_avatar
    QiniuWorker.perform_async('init_user_avatar', user_id: self.id)
  end


  def send_welcome_mail
    SystemMailWorker.perform_async('welcome_mail', send_to: self.email)
  end

  def create_default_category
    category = self.categories.build(name: '我的文章', description: '默认文章分类')
    category.save
  end


end
