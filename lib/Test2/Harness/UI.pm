package Test2::Harness::UI;
use strict;
use warnings;

our $VERSION = '0.000001';

use Test2::Harness::UI::Request;
use Test2::Harness::UI::Controller::Page;
use Test2::Harness::UI::Controller::Upload;
use Test2::Harness::UI::Controller::User;

use Test2::Harness::Util::JSON qw/encode_json/;

use Test2::Harness::UI::Util::Errors qw/ERROR_404 ERROR_405 ERROR_401/;

use Test2::Harness::UI::Util::HashBase qw/-config_file -schema/;

my %ROUTING = (
    "/upload" => 'Test2::Harness::UI::Controller::Upload',
    "/user"   => 'Test2::Harness::UI::Controller::User',
    "/"       => 'Test2::Harness::UI::Controller::Page',
);

sub to_app {
    my $self = shift;

    return sub {
        my $env = shift;

        my $req = Test2::Harness::UI::Request->new(env => $env, schema => $self->{+SCHEMA});

        my $path = $req->path;
        $path =~ s{/+$}{}g unless $path eq '/';

        $self->wrap($ROUTING{$path}, $req);
    }
}

sub wrap {
    my $self = shift;
    my ($class, $req) = @_;

    my ($headers, $content);
    my $ok = eval {
        die ERROR_404() unless $class;

        my $controller = $class->new(request => $req, schema => $self->schema);
        ($content, $headers) = $controller->process();

        1;
    };
    my $err = $@;

    return [200, $headers, [$content]] if $ok;

    if ($err) {
        return [401, ['Content-Type' => 'text/plain'], ["401 Unauthorized\n"]]
            if $err == ERROR_401();

        return [404, ['Content-Type' => 'text/plain'], ["404 page not found\n"]]
            if $err == ERROR_404();

        return [405, ['Content-Type' => 'text/plain'], ["405 Method not allowed\n"]]
            if $err == ERROR_405();

        return [500, ['Content-Type' => 'text/plain'], ["$err\n"]]
            if $ENV{T2_HARNESS_UI_ENV} eq 'dev';
    }

    return [500, ['Content-Type' => 'text/plain'], ["Internal Server Error\n"]];
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::UI - Work in progress

=head1 DESCRIPTION

Work in progress

=head1 SYNOPSIS

TODO

=head1 SOURCE

The source code repository for Test2-Harness-UI can be found at
F<http://github.com/Test-More/Test2-Harness-UI/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2018 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut