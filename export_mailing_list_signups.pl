#!perl
use v5.14;
use warnings;
use DBI;
use Net::Google::Drive::Simple;
use DateTime;

use constant DB_NAME     => 'bodgery_liability';
use constant DB_USERNAME => '';
use constant DB_PASSWORD => '';


sub get_dbh
{
    return $dbh if defined $dbh;
    $dbh = DBI->connect(
        'dbi:Pg:dbname=' . DB_NAME,
        DB_USERNAME,
        DB_PASSWORD,
        {
            AutoCommit => 1,
            RaiseError => 0,
        },
    ) or die "Could not connect to database: " . DBI->errstr;
    return $dbh;
}

sub get_pending_signups
{
    my ($dbh) = @_;
    my $sql = 'SELECT id, email FROM guest_signin'
        . ' WHERE is_mailing_list_exported = FALSE';
    my $sth = $dbh->prepare_cached( $sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute()
        or die "Can't execute statement: " . $sth->errstr;
    
    my (@ids, @emails);
    while( my $row = $sth->fetchrow_hashref ) {
        push @ids => $row->{id};
        push @emails => $row->{email};
    }

    $sth->finish;
    return (\@ids, \@emails);
}

sub make_filename
{
    my $now = DateTime->now;
    my $name = 'email_signups_' . $now->ymd('_');
    return $name;
}

sub save_emails_to_google
{
    my ($emails) = @_;
    my @emails = @$emails;

    my $gd = Net::Google::Drive::Simple->new;
    my $filename = make_filename();

    return;

}

sub mark_signups_done
{
    my ($ids) = @_;
    my @ids = @$ids;
    my $sql = 'UPDATE guest_signin SET is_mailing_list_exported = TRUE'
        . ' WHERE id IN (' . join( ',', ('?') x scalar(@ids) ) . ')';

    my $sth = $dbh->prepare_cached( $sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @ids )
        or die "Can't execute statement: " . $sth->errstr;
    $sth->finish;

    return;
}


{
    my $dbh = get_dbh;
    my ($ids, $emails) = get_pending_signups( $dbh );
    save_emails_to_google( $emails );
    mark_signups_done( $ids );
}
