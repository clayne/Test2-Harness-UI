package Test2::Harness::UI::Controller::Events;
use strict;
use warnings;

use Data::GUID;
use List::Util qw/max/;
use Text::Xslate(qw/mark_raw/);
use Test2::Harness::UI::Util qw/share_dir/;
use Test2::Harness::UI::Response qw/resp error/;
use Test2::Harness::Util::JSON qw/encode_json decode_json/;

use parent 'Test2::Harness::UI::Controller';
use Test2::Harness::UI::Util::HashBase;

sub title { 'Events' }

sub handle {
    my $self = shift;
    my ($route) = @_;

    my $req = $self->{+REQUEST};
    my $res = resp(200);
    my $user = $req->user;
    my $schema = $self->{+CONFIG}->schema;

    die error(404 => 'Missing route') unless $route;
    my $it = $route->{name_or_id} or die error(404 => 'No name or id');

    my @events;

    if ($route->{from} eq 'job') {
        my $job_id = $it;
        my $job = $schema->resultset('Job')->find({job_id => $job_id})
            or die error(404 => 'Invalid Job');

        $job->verify_access('r', $user) or die error(401);

        @events = $schema->resultset('Event')->search(
            {'job_id' => $job_id, parent_id => undef},
            {order_by => ['event_ord', 'event_id']},
        )->all;
    }
    elsif ($route->{from} eq 'event') {
        my $event_id = $it;
        my $event = $schema->resultset('Event')->find({event_id => $event_id})
            or die error(404 => 'Invalid Event');

        $event->verify_access('r', $user) or die error(401);

        @events = $schema->resultset('Event')->search(
            {'parent_id' => $event_id},
            {order_by => ['event_ord', 'event_id']},
        )->all;
    }
    else {
        die error(501);
    }

    $res->stream(
        env          => $req->env,
        content_type => 'application/x-jsonl',

        done  => sub { !@events },
        fetch => sub {
            my $event = shift @events or return;

            return encode_json($event) . "\n";
        },
    );

    return $res;
}

1;