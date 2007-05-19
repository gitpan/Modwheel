# $Id: Configure.pm,v 1.1 2007/05/19 01:33:43 ask Exp $
# $Source: /opt/CVS/Modwheel/lib/Modwheel/Configure.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/05/19 01:33:43 $
package Modwheel::Configure;
use strict;
use warnings;
use YAML::Syck;
use Term::ANSIColor;
use Modwheel::Session;
use Modwheel::BuildConfig;
use Modwheel::REPL::Prompt;
use version; our $VERSION = qv('0.3.2');

my $prefix     = Modwheel::BuildConfig->get_value('prefix');
my $cfgfile    = File::Spec->catfile($prefix, 'config', 'modwheelconfig.yml');
my $templates  = File::Spec->catdir( $prefix, 'Templates');
my $repository = File::Spec->catdir( $prefix, 'Repository');

my %default_siteconfig = (
    locale            => 'en_EN',
    database        =>{
        type        => 'MySQL',
        name        => 'modwheel',
        host        => 'localhost',
        username     => 'modwheel',

    },
    repositoryurl     => '/rep',
    templatedriver     => 'TT',
    directoryindex     => 'index.html',
    TT                =>{
        plugins     =>{
            Filter    => 'Template::Plugin::Filter',
            URL     => 'Template::Plugin::URL',
            Date    => 'Template::Plugin::Date',
        },
    },
);

my %default_adminsiteconfig = %default_siteconfig;
$default_adminsiteconfig{NeverDetach} = 'Yes';

my %default_user_site = %default_siteconfig;

my %default_default = (
    active            => 1,
    groupo            => 100,
    inherit            => 1,
    owner            => 100,
    parent            => 1,
    detach           => 0,
);

my %default_global = (
    title            => 'Modwheel',
    directoryindex     => 'index.html',
    templatedriver     => 'TT',
    debug            => 0,
);

my %default_shortcuts = (
    http            => '<a href="[type]:[content]">[name]</a>',
    https            => '<a href="[type]:[content]">[name]</a>',
    ftp                => '<a href="[type]:[content]">[name]</a>',
    mail            => '<a href="mailto:[content]">[name]</a>',
    cpan            =>
        '<a href="http://search.cpan.org?query=[:content]&amp;mode=All">[name]</a>',
    perldoc         =>
        '<a href="http://perldoc.com/cgi-bin/htsearch?words=[:content]">[name]</a>',
    google            =>
        '<a href="http://google.startsiden.no/?q=[:content]">[name]</a>',
    cpanauthor         =>
        '<a href="http://search.cpan.org/~[:content]">[name]</a>',
);

sub configure {
    my ($self) = @_;

    my $prompt = Modwheel::REPL::Prompt->new();
    my $ANSI_bold   = color 'bold';
    my $ANSI_reset  = color 'reset';

    my $config = {};
    if($cfgfile && -f $cfgfile) {
        $config = YAML::Syck::LoadFile($cfgfile);
    }
    else {
        print
            "Configuration file does not exist. Creating new configuration...\n\n";
        $config->{default}   = \%default_default;
        $config->{global}    = \%default_global;
        $config->{shortcuts} = \%default_shortcuts;
    }

    my $a = $prompt->yes_no(
        'There are no sites defined, would you like to create a new site?');
    my $site_name; # name of Admin site.
    my $user_site; # name of User site;
    if ($a) {
        print "OK!\n";

        # ### Admin Site name.
        print
            "First we need to define an Admin site.\nThe ADMIN site is the site used by content managers to edit the content of the site.\n";
        $site_name
            = $prompt->using_default('What is the name of this ADMIN site?',
            'Admin');
        print    "OK! Name is $site_name, good...\n\n";

        while(my($key, $value) = each %default_adminsiteconfig) {
            $config->{site}{$site_name}{$key} = $value;
        }

        # ### Site template directory.
        print"Now we have to specify a template directory for this site.\n",
            "Since this is a admin site you'd probably want to use SimpleAdmin.\n";
        my $site_template = $prompt->using_default(
            'Where is the template directory for this Site',
            "$templates/SimpleAdmin");
        $config->{site}{$site_name}{templatedir} = $site_template;
        print
            "Great! Template directory for $site_name is now $site_template\n\n";

        # ### Site repository directory.
        print
            "Modwheel lets users upload files to a place called the Repository. While the database keeps track of these files\n",
            "the files themselves are stored in a directory on the filesystem. You can have different repository directories for different sites.\n";
        my $site_rep         = $prompt->using_default(
            'Where is the repository directory for this site?',
            "$repository");
        $config->{site}{$site_name}{repository} = $site_rep;
        print"Nice. Repository directory for $site_name is now $site_rep.\n\n";

        # ### Site repository URL.
        print
            "For users to access the repository from their browser we need to specify a location to use.\n",
            "The default for this location is '/rep', but you can change this to the location you want.\n";
        my $site_repurl     = $prompt->using_default(
            'What is the url location for the repository?',
            $default_siteconfig{repositoryurl});
        $config->{site}{$site_name}{repositoryurl} = $site_repurl;
        print
            "Good. Now you must make a corresponding entry in your httpd config. for Apache this would be:\n",
            "\tAlias $site_repurl \"$site_rep\"\n\n",

            # ### Site directory index.
            "When users points their browser to a location but doesn't specify a file, we need a default file to send\n",
            "this file is called the directory index and is usually 'index.html'.\n";
        my $site_dir_index = $prompt->using_default(
            'What is the directory index file name for this site?',
            $default_siteconfig{directoryindex});
        $config->{site}{$site_name}{directoryindex} = $site_dir_index;
        print"Super :-)\nNow let's go on to the database configuration\n\n\n";

        # ### Database type.
        print
            "A wide range of database solutions are available, all of them with their own set of strengths and weaknesses.\n",
            "therefore Modwheel is designed to make it easy to extend the list of supported databases.\n",
            "For the moment Modwheel has only been tested with MySQL, so the use of other systems is experimental.\n";
        my $site_db_type = $prompt->using_default(
            'What type of database do you want to use?',
            'MySQL', 'PostgreSQL');
        $config->{site}{$site_name}{database}{type} = $site_db_type ;
        print    "OK! This site will now use a $site_db_type  database.\n";

        # ### Database host.
        print
            "You can either connect to a local database or connect to a remote database. If the database is local the host\n",
            "should be 'localhost', if it's remote you enter the host name or ip of the database server.\n";
        my $site_db_host    = $prompt->using_default(
            'What is the hostname/ip-address of the database server?',
            'localhost');
        $config->{site}{$site_name}{database}{host} = $site_db_host;
        print"OK! We now connect to a $site_db_type  on host $site_db_host\n\n";

        # ### Database name.
        print
            "The name of the database is the name you use in statements like 'USE mydatabase'. If you don't have one yet,\n",
            "don't worry as we will create a database with the name you provide here later on.\n";
        my $site_db_name= $prompt->using_default(
            'What is the name of the database to use?','modwheel');
        $config->{site}{$site_name}{database}{name} = $site_db_name;
        print    "OK! The name of the database is now $site_db_name\n";

        # ### Database username.
        print
            "We need a database user so we can connect to the database If you don't have one, please create one now!\n",
            "The default username is 'modwheel', but as always you can change this to your liking.\n";
        my $site_db_user= $prompt->using_default(
            'What is the name of the database to use?','modwheel');
        $config->{site}{$site_name}{database}{username} = $site_db_user;
        print
            "Nice! We'll connect to the database with username $site_db_user.\n\n";

        # ### Database password.
        print
            "For security reasons it's always a good idea to require a password when someone connects to your database.\n",
            "Modwheel needs this password to be able to connect, but remember that the password is stored as plain text in the\n",
            "configuration file, so it's smart to change the owner of this file to the http user.\n";
        print
            "First you have to select if you want the characters you type be echoed to the screen or not, then you type in the\n",
            "password.\n";
        my $disable_echo = $prompt->yes_no(
            'Do you want to disable echo as you type in your password?');
        my $site_db_pwd;
        if($disable_echo) {
            $site_db_pwd    = $prompt->password(
                "Please enter password for user $site_db_user\@$site_db_host ");
        }
        else {
            $site_db_pwd    = $prompt->prompt(
                "Please enter password for user $site_db_user\@$site_db_host ");
        }
        $config->{site}{$site_name}{database}{password} = $site_db_pwd;
        print   "OK!\n\n\n";

        print
            "Now that the admin site is configured properly we need to create a site for users.\n",
            "The USER site is the site where objects (like articles, blog entries, news, links etc) created on the\n",
            "site are published for other users to read. A lot of configurations options will be taken from the admin site\n",
            "you created above. If for some reason you want to tweak this site to be different from the admin you have to\n",
            "edit the configuration file $cfgfile by hand.\n";
        $user_site
            = $prompt->using_default('What is the name of this USER site',
            'User');
        print
            "Great! User site for admin site $site_name is now $user_site.\n\n";

        print"Now we have to specify a template directory for this site.\n",
            "Since this is a user site you would probably want to use Simple.\n";
        $site_template= $prompt->using_default(
            'Where is the template directory for this Site',
            "$templates/Simple");
        print
            "Great! Template directory for $site_name is now $site_template\n\n";

        while(my($key, $value) = each %default_user_site) {
            $config->{site}{$user_site}{$key} = $value;
        }
        $config->{site}{$user_site}{repository} = $site_rep;
        $config->{site}{$user_site}{templatedir} = $site_template;
        $config->{site}{$user_site}{repositoryurl} = $site_repurl;
        $config->{site}{$user_site}{directoryindex} = $site_dir_index;
        $config->{site}{$user_site}{database}{type} = $site_db_type ;
        $config->{site}{$user_site}{database}{host} = $site_db_host;
        $config->{site}{$user_site}{database}{name} = $site_db_name;
        $config->{site}{$user_site}{database}{username} = $site_db_user;
        $config->{site}{$user_site}{database}{password} = $site_db_pwd;

        # set some global options now that we have site directives:
        $config->{global}{defaultsite} = $user_site;
        $config->{global}{templatedir} = $site_template;
    }

    if(-f $cfgfile) {
        my $confirm = $prompt->no_yes(
            'Warning: Configuration file already exists, are you sure you want to overwrite the current config?'
        );
        if($confirm) {
            YAML::Syck::DumpFile($cfgfile, $config);
            print "OK! Configuration saved to $cfgfile\n\n";
        }
    }
    else {
        YAML::Syck::DumpFile($cfgfile, $config);
        print "Configuration saved to $cfgfile.\n\n";
    }

    return;
}

sub welcome  {
    my $ANSI_bold   = color 'bold';
    my $ANSI_reset  = color 'reset';
    my $out = <<"__WELCOME__"
${ANSI_bold}MODWHEEL CONFIGURATION${ANSI_reset}
Welcome to the modwheel configuration utility.
If you don't know the answer to a question, the default will be OK to use,
If there are several defalt answers available for a question the suggested
one is identified at the prompt as all uppercase and in bold.

Good luck :-)
---

__WELCOME__
        ;
    return $out;
}

1;
