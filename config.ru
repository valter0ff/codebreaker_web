require './autoload'

use Rack::Reloader
use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           expire_after: 2_592_000,
                           domain: ENV['DOMAIN'] || '127.0.0.1',
                           secret: ENV['SECRET'] || 'change_me'
use Rack::Static, urls: ['/assets'], root: 'public'
use Rack::Static, urls: %w[/bootstrap-v4-rtl /jquery], root: 'node_modules'
use Rack::Flash, accessorize: %i[notice error]

run App
