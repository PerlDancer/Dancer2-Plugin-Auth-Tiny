use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Auth::Tiny;
# ABSTRACT: Require logged-in user for specified routes
# VERSION

use Carp qw/croak/;

use Dancer ':syntax';
use Dancer::Plugin;

my %conf = (
  login_route   => '/login',
  logged_in_key => 'user',
  callback_key  => 'return_url',
  %{ plugin_setting() },
);

my %dispatch = ( login => \&_build_login, );

sub extend {
  my ( $class, @args ) = @_;
  unless ( @args % 2 == 0 ) {
    croak "arguments to $class\->extend must be key/value pairs";
  }
  %dispatch = ( %dispatch, @args );
}

register 'needs' => sub {
  my ( $self, $condition, @args ) = plugin_args(@_);

  my $builder = $dispatch{$condition};

  if ( ref $builder eq 'CODE' ) {
    return $builder->(@args);
  }
  else {
    croak "Unknown authorization condition '$condition'";
  }
};

sub _build_login {
  my ($coderef) = @_;
  return sub {
    if ( session $conf{logged_in_key} ) {
      goto \&$coderef;
    }
    else {
      return redirect uri_for( $conf{login_route},
        { $conf{callback_key} => uri_for( request->path, request->params ) } );
    }
  };
}

register_plugin for_versions => [ 1, 2 ];

1;

=for Pod::Coverage method_names_here

=head1 SYNOPSIS

  use Dancer::Plugin::Auth::Tiny;

=head1 DESCRIPTION

This module might be cool, but you'd never know it from the lack
of documentation.

=head1 USAGE

Good luck!

=head1 SEE ALSO

Maybe other modules do related things.

=cut

# vim: ts=2 sts=2 sw=2 et:
