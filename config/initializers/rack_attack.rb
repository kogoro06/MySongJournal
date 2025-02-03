class Rack::Attack
  # X-XSS-Protection
  safelist('allow from all') do |req|
    req.env['HTTP_X_XSS_PROTECTION'] = '1; mode=block'
    true
  end

  # URLのバリデーション
  blocklist('block malicious urls') do |req|
    if req.path.include?('/users/')
      url_param = req.params['x_link']
      if url_param.present?
        uri = URI.parse(url_param)
        !(uri.scheme =~ /\Ahttps?\z/ && uri.host =~ /\A(www\.)?(twitter|x)\.com\z/)
      end
    end
  rescue URI::InvalidURIError
    true
  end
end

# アプリケーションの設定
Rails.application.config.middleware.use Rack::Attack