#!perl
# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use v5.14;
use warnings;
use Mojolicious::Lite;
use DBI;
use DateTime;
use File::Slurp 'read_file';
use YAML 'Load';

use constant CONFIG_FILE => 'config.yml';
my $CONFIG = read_config( CONFIG_FILE );

use constant LIABILITY_INSERT => q{INSERT INTO liability_waivers}
    . q{ (full_name, check1, check2, check3, check4, zip, phone, email}
    . q{, emergency_contact_name, emergency_contact_phone, heard_from, signature)}
    . q{ VALUES (?, true, true, true, true, ?, ?, ?, ?, ?, ?, ?)};
use constant GUEST_INSERT => q{INSERT INTO guest_signin}
    . q{ (full_name, member_hosting, email, zip, join_mailing_list)}
    . q{ VALUES (?, ?, ?, ?, ?)};


get '/' => sub {
    my ($c) = @_;
    $c->reply->static( 'index.html' );
};

get '/guest-signin' => sub {
    my ($c) = @_;
    $c->render( template => 'guest_signin' );
};

post '/guest-signin' => sub {
    my ($c) = @_;
    my $name = $c->param( 'full_name' );
    my $email = $c->param( 'email' );
    my $hosting = $c->param( 'member_hosting' );
    my $heard_about_from = $c->param( 'heard_from' );
    my $do_join_mailing_list = $c->param( 'join_mailing_list' );
    my $zip = $c->param( 'zip' );

    # Force to boolean
    $do_join_mailing_list = !! $do_join_mailing_list;

    my $args = trim_args({
        name => $name,
        email => $email,
        hosting => $hosting,
        do_join_mailing_list => $do_join_mailing_list,
        zip => $zip,
    });

    my @errors = check_guest_params( $args );

    if( @errors ) {
        $c->render(
            template => 'guest_signin',
            errors => \@errors,
            args => $args,
        );
    }
    else {
        save_guest_data( $args );
        $c->render( template => 'guest_signin_submit' );
    }
};

get '/liability' => sub {
    my $c = shift;
    $c->render( template => 'liability' );
};

post '/liability' => sub {
    my $c = shift;
    my $name = $c->param( 'name' );
    my $check1 = $c->param( 'check1' );
    my $check2 = $c->param( 'check2' );
    my $check3 = $c->param( 'check3' );
    my $check4 = $c->param( 'check4' );
    my $zip = $c->param( 'zip' );
    my $phone = $c->param( 'phone' );
    my $email = $c->param( 'email' );
    my $emerg_name = $c->param( 'emergency_contact_name' );
    my $emerg_phone = $c->param( 'emergency_contact_phone' );
    my $hosting = $c->param( 'member_hosting' );
    my $heard_about_from = $c->param( 'heard_from' );
    my $do_join_mailing_list = $c->param( 'join_mailing_list' );
    my $signature = $c->param( 'output' );

    # Force to boolean
    $do_join_mailing_list = !! $do_join_mailing_list;

    my $args = trim_args({
        name => $name,
        check1 => $check1,
        check2 => $check2,
        check3 => $check3,
        check4 => $check4,
        zip => $zip,
        phone => $phone,
        email => $email,
        emerg_name => $emerg_name,
        emerg_phone => $emerg_phone,
        hosting => $hosting,
        heard_about_from => $heard_about_from,
        do_join_mailing_list => $do_join_mailing_list,
        signature => $signature,
    });

    my @errors = check_liability_params( $args );

    if( @errors ) {
        $c->render(
            template => 'liability',
            errors => \@errors,
            args => $args,
        );
    }
    else {
        save_liability_data( $args );
        save_guest_data( $args );
        $c->render( template => 'liability_submit' );
    }
};


sub check_liability_params
{
    my ($args) = @_;
    my @errors;
    
    push @errors => 'Name not filled in' unless $args->{name};
    push @errors => 'Name should be only letters and spaces'
        # Using \w technically allows numbers, but that's OK
        unless $args->{name} =~ /\A (?:[\w\s\.\-]*) \z/x;

    push @errors => 'First checkbox is required' unless $args->{check1} == 1;
    push @errors => 'Second checkbox is required' unless $args->{check2} == 1;
    push @errors => 'Third checkbox is required' unless $args->{check3} == 1;
    push @errors => 'Fourth checkbox is required' unless $args->{check4} == 1;

    push @errors => 'Zip not filled in' unless $args->{zip};
    push @errors => 'Zip should only be numbers and dashes'
        unless $args->{zip} =~ /\A (?:[\d\-]*) \z/x;

    push @errors => 'Phone not filled in' unless $args->{phone};
    push @errors => 'Phone should only be numbers, spaces, dashes, and parens'
        unless $args->{phone} =~ /\A (?:[\d\s\-\(\)]*) \z/x;

    if( $args->{email} ) {
        push @errors => 'Email should have an "@" symbol'
            unless $args->{email} =~ /@/x;
        push @errors => 'Email should not have a "<" symbol'
            # Just for XSS protection
            if $args->{email} =~ /</x;
    }

    push @errors => 'Emergency Contact Name not filled in' unless $args->{emerg_name};
    push @errors => 'Emergency Contact Name should only be letters and spaces'
        unless $args->{emerg_name} =~ /\A (?:[\w\s\.\-]*) \z/x;

    push @errors => 'Emergency Contact Phone not filled in' unless $args->{emerg_phone};
    push @errors => 'Emergency Contact Phone should only be numbers, spaces, dashes, and parens'
        unless $args->{emerg_phone} =~ /\A (?:[\d\s\-\(\)]*) \z/x;

    push @errors => 'Hosting Member should only be letters and spaces'
        unless $args->{hosting} =~ /\A (?:[\w\s\.\-]*) \z/x;

    push @errors => 'Heard About From should only be letters and spaces'
        unless $args->{heard_about_from} =~ /\A (?:[\w\s\.\-]*) \z/x;

    # TODO signature
    #push @errors => 'Signature should be filled in' unless $args->{signature};


    return @errors;
}

sub check_guest_params
{
    my ($args) = @_;
    my @errors;

    push @errors => 'Name not filled in' unless $args->{name};
    push @errors => 'Name should be only letters and spaces'
        # Using \w technically allows numbers, but that's OK
        unless $args->{name} =~ /\A (?:[\w\s\.\-]*) \z/x;

    push @errors => 'Zip not filled in' unless $args->{zip};
    push @errors => 'Zip should only be numbers and dashes'
        unless $args->{zip} =~ /\A (?:[\d\-]*) \z/x;

    if( $args->{email} ) {
        push @errors => 'Email should have an "@" symbol'
            unless $args->{email} =~ /@/x;
        push @errors => 'Email should not have a "<" symbol'
            # Just for XSS protection
            if $args->{email} =~ /</x;
    }

    push @errors => 'Hosting Member should only be letters and spaces'
        unless $args->{hosting} =~ /\A (?:[\w\s\.\-]*) \z/x;

    return @errors;
}

sub save_liability_data
{
    my ($args) = @_;
    my %args = %$args;

    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( LIABILITY_INSERT )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @args{qw{ name zip phone email emerg_name emerg_phone 
        heard_about_from }}, '' )
        or die "Can't execute statement: " . $sth->errstr;
    $sth->finish;

    return;
}

sub save_guest_data
{
    my ($args) = @_;
    my %args = %$args;

    my $do_join = $args->{do_join_mailing_list} ? 1 : 0;

    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( GUEST_INSERT )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @args{qw{ name hosting email zip }}, $do_join )
        or die "Can't execute statement: " . $sth->errstr;
    $sth->finish;

    return;
}

sub trim_args
{
    my ($args) = @_;

    my %trimmed_args = map {
        my $value = $args->{$_};
        $value =~ s/\A\s*//;
        $value =~ s/\s*\z//;
        ($_ => $value);
    } keys %$args;

    return \%trimmed_args;
}


{
    my $dbh;
    sub get_dbh
    {
        return $dbh if defined $dbh;
        $dbh = DBI->connect(
            'dbi:Pg:dbname=' . $CONFIG->{postgresql}{database},
            $CONFIG->{postgresql}{username},
            $CONFIG->{postgresql}{passwd},
            {
                AutoCommit => 1,
                RaiseError => 0,
            },
        ) or die "Could not connect to database: " . DBI->errstr;
        return $dbh;
    }

    sub My::Test::set_dbh
    {
        my ($in_dbh) = @_;
        $dbh = $in_dbh;
        return 1;
    }
}

sub read_config
{
    my ($file) = @_;
    my $contents = read_file( $file );
    my $config = Load( $contents );
    return $config;
}


app->secrets([ 'placeholder_passphrase_to_make_log_shutup' ]);
app->start;
