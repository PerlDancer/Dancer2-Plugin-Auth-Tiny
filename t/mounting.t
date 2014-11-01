use strict;
use warnings;
use Test::More 0.96 tests => 2;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

{
    package App::Root;
    use Dancer2;
    get '/' => sub {'Root'};
}

{
    package App::Auth;
    use Dancer2;
    use Dancer2::Plugin::Auth::Tiny;
    get '/'    => sub {'Auth'};
    get '/try' => needs login => sub {1};
}

my $app = builder {
    mount '/'     => App::Root->to_app;
    mount '/auth' => App::Auth->to_app;
};

my $test = Plack::Test->create($app);

subtest 'Default' => sub {
    is( $test->request( GET '/' )->content, 'Root', '/ is Root' );
    is( $test->request( GET '/auth' )->content, 'Auth', '/auth is Auth' );
};

subtest 'Authenticate' => sub {
    my $res = $test->request( GET '/auth/try' );
    ok( $res->is_redirect, '[GET /auth/try] redirect' );
    like(
        $res->header('Location'),
        qr{/auth/login\?},
        '/auth/try redirects to /auth/login',
    );

    like(
        $res->header('Location'),
        qr{\?return_url=.+%2Fauth%2Ftry},
        '/auth/try return url parameter is /auth/try',
    );
};

