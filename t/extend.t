use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use File::Temp 0.19; # newdir
use LWP::UserAgent;
use Test::TCP;

use Dancer2 ':syntax';
use Dancer2::Plugin::Auth::Tiny;

Dancer2::Plugin::Auth::Tiny->extend(
  admin => sub {
    my ($dsl, $coderef) = @_;
    return sub {
      if ( $dsl->app->session("is_admin") ) {
        goto \&$coderef;
      }
      else {
        return "Access denied";
      }
    };
  }
);

test_tcp(
  client => sub {
    my $port = shift;
    my $url  = "http://localhost:$port/";

    my $ua = LWP::UserAgent->new( cookie_jar => {} );

    my $res = $ua->get( $url . "public" );
    like $res->content, qr/index/i, "GET /public works";

    $res = $ua->get( $url . "admin" );
    like $res->content, qr/denied/i, "GET /admin reports denied";

    $res = $ua->get( $url . "login" );
    like $res->content, qr/login/i, "GET /login";

    $res = $ua->get( $url . "admin" );
    like $res->content, qr/admin/i, "GET /admin now works";

    $res = $ua->get( $url . "logout" );
    like $res->content, qr/index/i, "GET /logout redirects to public";

    $res = $ua->get( $url . "admin" );
    like $res->content, qr/denied/i, "GET /admin reports denied again";
  },

  server => sub {
    my $port = shift;

    set confdir     => '.';
    set port        => $port, startup_info => 0;
    set show_errors => 1;
    set session     => 'Simple';

    get '/public' => sub { return 'index' };

    get '/admin' => needs admin => sub { return 'admin' };

    get '/login' => sub {
      session "user"     => "Larry Wall";
      session "is_admin" => 1;
      return "login";
    };

    get '/logout' => sub {
      context->destroy_session;
      redirect uri_for('/public');
    };

    Dancer2->runner->server->port($port);
    start;
  },
);

done_testing;
# COPYRIGHT
