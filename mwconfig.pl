#!/usr/bin/perl -w
use strict;
use YAML;
use Term::ReadKey;
use Term::Complete;
use Term::ANSIColor;
use Modwheel::Session;

my($cfgfile, $prefix, $templates, $repository) = @ARGV;
my $Bold  = color 'bold';
my $Reset = color 'reset';

my $ASK_TEXT    = 0x00;    # ask for a text string, loops if not answered.
my $ASK_TEXTDEF = 0x01; # ask for text, if no answer returns the provided default.
my $ASK_NUMBER  = 0x02;    # ask for a number, loops if answer is not a number.
my $ASK_LIST    = 0x03;    # ask for a text string, loops if the answer is not in the suggestion list.
my $ASK_LISTDEF = 0x04; # ask for a text string that is in the given list, if there is no reply it uses the provided default.
my $ASK_DEFAULT = 0x05;    # ask for a text string, if the user doesn't answer it returns the provided default.
my $ASK_PASSWD    = 0x06; # turn of terminal echo.


my %default_siteconfig = (
    locale            => 'en_EN',
    database        =>
    {
        type        => 'MySQL',
        name        => 'modwheel',
        host        => 'localhost',
        username     => 'modwheel',
        
    },
    repositoryurl     => '/rep',
    templatedriver     => 'TT',
    directoryindex     => 'index.html',
    TT                =>
    {
        plugins     =>
        {
            Filter    => 'Template::Plugin::Filter',
            URL     => 'Template::Plugin::URL',
            Date    => 'Template::Plugin::Date',
        },
    },
);

my %default_adminsiteconfig = %default_siteconfig;
$default_adminsiteconfig{NeverDetach} = 'Yes';

my %default_usersiteconfig = %default_siteconfig;

my %default_default = (
    active            => 1,
    groupo            => 100,
    inherit            => 1,
    owner            => 100,
    parent            => 1,
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
    cpan            => '<a href="http://search.cpan.org?query=[:content]&amp;mode=All">[name]</a>',
    perldoc         => '<a href="http://perldoc.com/cgi-bin/htsearch?words=[:content]">[name]</a>',
    google            => '<a href="http://google.startsiden.no/?q=[:content]">[name]</a>',
    cpanauthor         => '<a href="http://search.cpan.org/~[:content]">[name]</a>',
);

$prefix ||= "/opt/modwheel";
$templates ||= "$prefix/Templates";
$repository ||= "$prefix/Repository";
$cfgfile ||= "$prefix/config/modwheelconfig.yml";

print qq#
${Bold}MODWHEEL CONFIGURATION${Reset}
Welcome to the modwheel configuration utility.
If you don't know the answer to a question, the default will be OK to use,
If there are several defalt answers available for a question the suggested
one is identified at the prompt as all uppercase and in bold.

Good luck :-)
---

# ;

my $config = { };
if($cfgfile && -f $cfgfile) {
    $config = YAML::LoadFile($cfgfile);
} else {
    print "Configuration file does not exist. Creating new configuration...\n\n";
    $config->{default}   = \%default_default;
    $config->{global}    = \%default_global;
    $config->{shortcuts} = \%default_shortcuts;
}
my $a; #answer


$a = ask($ASK_LISTDEF, 'There are no sites defined, would you like to create a new site?');
my $siteName; # name of Admin site.
my $userSite; # name of User site;
if($a =~ /YES/i) {
    print "OK!\n";

    # ### Admin Site name.
    print    "First we need to define an Admin site.\nThe ADMIN site is the site used by content managers to edit the content of the site.\n";
    $siteName = ask($ASK_TEXTDEF, 'What is the name of this ADMIN site?', 'Admin');
    print    "OK! Name is $siteName, good...\n\n";

    while(my($key, $value) = each %default_adminsiteconfig) {
        $config->{site}{$siteName}{$key} = $value;
    }
    
    # ### Site template directory.
    print    "Now we have to specify a template directory for this site.\n",
            "Since this is a admin site you'd probably want to use SimpleAdmin.\n";
    my $siteTemplate = ask($ASK_TEXTDEF, "Where is the template directory for this Site", "$templates/SimpleAdmin");
    $config->{site}{$siteName}{templatedir} = $siteTemplate;
    print   "Great! Template directory for $siteName is now $siteTemplate\n\n";

    # ### Site repository directory.
    print    "Modwheel lets users upload files to a place called the Repository. While the database keeps track of these files\n",
            "the files themselves are stored in a directory on the filesystem. You can have different repository directories for different sites.\n";
    my $siteRep         = ask($ASK_TEXTDEF, "Where is the repository directory for this site?", "$repository");
    $config->{site}{$siteName}{repository} = $siteRep;
    print   "Nice. Repository directory for $siteName is now $siteRep.\n\n";

    # ### Site repository URL.
    print    "For users to access the repository from their browser we need to specify a location to use.\n",
            "The default for this location is '/rep', but you can change this to the location you want.\n";
    my $siteRepUrl     = ask($ASK_TEXTDEF, "What is the url location for the repository?", $default_siteconfig{repositoryurl});
    $config->{site}{$siteName}{repositoryurl} = $siteRepUrl;
    print    "Good. Now you must make a corresponding entry in your httpd config. for Apache this would be:\n",
            "\tAlias $siteRepUrl \"$siteRep\"\n\n",

    # ### Site directory index.
            "When users points their browser to a location but doesn't specify a file, we need a default file to send\n",
            "this file is called the directory index and is usually 'index.html'.\n";
    my $siteDirIndex = ask($ASK_TEXTDEF, "What is the directory index file name for this site?", $default_siteconfig{directoryindex});
    $config->{site}{$siteName}{directoryindex} = $siteDirIndex;
    print    "Super :-)\nNow let's go on to the database configuration\n\n\n";

    # ### Database type.
    print    "A wide range of database solutions are available, all of them with their own set of strengths and weaknesses.\n",
            "therefore Modwheel is designed to make it easy to extend the list of supported databases.\n",
            "For the moment Modwheel has only been tested with MySQL, so the use of other systems is experimental.\n";
    my $siteDBType   = ask($ASK_LISTDEF, "What type of database do you want to use?", "MySQL", "PostgreSQL");
    $config->{site}{$siteName}{database}{type} = $siteDBType;
    print    "OK! This site will now use a $siteDBType database.\n";

    # ### Database host.
    print    "You can either connect to a local database or connect to a remote database. If the database is local the host\n",
            "should be 'localhost', if it's remote you enter the host name or ip of the database server.\n";
    my $siteDBHost    = ask($ASK_TEXTDEF, "What is the hostname/ip-address of the database server?", "localhost");
    $config->{site}{$siteName}{database}{host} = $siteDBHost;
    print     "OK! We now connect to a $siteDBType on host $siteDBHost\n\n";

    # ### Database name.
    print    "The name of the database is the name you use in statements like 'USE mydatabase'. If you don't have one yet,\n",
            "don't worry as we will create a database with the name you provide here later on.\n";
    my $siteDBName    = ask($ASK_TEXTDEF, "What is the name of the database to use?", "modwheel");
    $config->{site}{$siteName}{database}{name} = $siteDBName;
    print    "OK! The name of the database is now $siteDBName\n";

    # ### Database username.
    print    "We need a database user so we can connect to the database If you don't have one, please create one now!\n",
            "The default username is 'modwheel', but as always you can change this to your liking.\n";
    my $siteDBUser    = ask($ASK_TEXTDEF, "What is the name of the database to use?", "modwheel");
    $config->{site}{$siteName}{database}{username} = $siteDBUser;
    print    "Nice! We'll connect to the database with username $siteDBUser.\n\n";

    # ### Database password.
    print    "For security reasons it's always a good idea to require a password when someone connects to your database.\n",
            "Modwheel needs this password to be able to connect, but remember that the password is stored as plain text in the\n",
            "configuration file, so it's smart to change the owner of this file to the http user.\n";
    print    "First you have to select if you want the characters you type be echoed to the screen or not, then you type in the\n",
            "password.\n";
    my $disableEcho = ask($ASK_LISTDEF, "Do you want to disable echo as you type in your password?");
    my $siteDBPwd;
    if($disableEcho =~ /YES/i) {
        $siteDBPwd    = ask($ASK_PASSWD, "Please enter password for user $siteDBUser\@$siteDBHost: ");
    } else {
        $siteDBPwd    = ask($ASK_TEXT, "Please enter password for user $siteDBUser\@$siteDBHost: ");
    }
    $config->{site}{$siteName}{database}{password} = $siteDBPwd;
    print   "OK!\n\n\n";

    print    "Now that the admin site is configured properly we need to create a site for users.\n",
            "The USER site is the site where objects (like articles, blog entries, news, links etc) created on the\n",
            "site are published for other users to read. A lot of configurations options will be taken from the admin site\n",
            "you created above. If for some reason you want to tweak this site to be different from the admin you have to\n",
            "edit the configuration file $cfgfile by hand.\n";
    $userSite = ask($ASK_TEXTDEF, "What is the name of this USER site?", "User");
    print    "Great! User site for admin site $siteName is now $userSite.\n\n";

    print    "Now we have to specify a template directory for this site.\n",
            "Since this is a user site you'd probably want to use Simple.\n";
    $siteTemplate = ask($ASK_TEXTDEF, "Where is the template directory for this Site", "$templates/Simple");
    print   "Great! Template directory for $siteName is now $siteTemplate\n\n";
    while(my($key, $value) = each %default_usersiteconfig) {
        $config->{site}{$userSite}{$key} = $value;
    }
    $config->{site}{$userSite}{repository} = $siteRep;
    $config->{site}{$userSite}{templatedir} = $siteTemplate;
    $config->{site}{$userSite}{repositoryurl} = $siteRepUrl;
    $config->{site}{$userSite}{directoryindex} = $siteDirIndex;
    $config->{site}{$userSite}{database}{type} = $siteDBType;
    $config->{site}{$userSite}{database}{host} = $siteDBHost;
    $config->{site}{$userSite}{database}{name} = $siteDBName;
    $config->{site}{$userSite}{database}{username} = $siteDBUser;
    $config->{site}{$userSite}{database}{password} = $siteDBPwd;

    # set some global options now that we have site directives:
    $config->{global}{defaultsite} = $userSite;
    $config->{global}{templatedir} = $siteTemplate;
}

if(-f $cfgfile) {
    my $confirm = ask($ASK_LISTDEF, "Warning: Configuration file already exists, are you sure you want to overwrite the current config?");
    if($confirm =~ /YES/i) {
        YAML::DumpFile($cfgfile, $config);
        print "OK! Configuration saved to $cfgfile\n\n";
    }
} else {
        YAML::DumpFile($cfgfile, $config);
        print "Configuration saved to $cfgfile.\n\n";
}

print    "OK, Now we're finished with configurating sites. Let's move on to other stuff.\n";
print    "\n\n";


my $dbtype = $config->{site}{$siteName}{database}{type};
my $dbname = $config->{site}{$siteName}{database}{name};
my $dbhost = $config->{site}{$siteName}{database}{host};
if($dbtype eq 'MySQL') {
    print    "You have already configured a database type, name, host and so on for a database, \n",
            "but you may not have created that database yet. Also, Modwheel needs to create some tables,\n",
            "and insert some defaults into this database. Please prepare your database now if you haven't done so yet.\n";
    my $prepareDB =            ask($ASK_LISTDEF, "Do you want to create the database $dbname\@$dbhost now?");
    if($prepareDB =~ /yes/i) {
        prepare_db_mysql($siteName);
    } else {
        print "OK!\n\n";
    }
}
else
{
    print    "*** Don't know how to create a modwheel database with $dbtype yet, you have to do this manually! ***\n";
}

print    "\n\n";
print    "If you're going to install Modwheel-Apache, I can create an example apache configuration file for you, \n",
            "just answer Yes to the next question and specify where you want this file.\n",
            "You can't just use this configuration file as-is however, it's just an example so you can see what you\n",
            "have to write in your main httpd.conf file.\n";
my $create_ap_conf =    ask($ASK_LISTDEF, "Do you want me to create an example Apache configuration file?");
if($create_ap_conf =~ /YES/i) {
    my $ap_conf_where =    ask($ASK_TEXTDEF, "Where should I save this example file?", "$prefix/config/modwheel-apache-example.conf");
    write_apache_config($ap_conf_where, $siteName, $userSite);
    print "OK! Example apache configuration file saved to $ap_conf_where\n\n";
} else {
    print "OK!\n\n";
}
    

sub prepare_db_mysql
{
    my($siteName) = @_;

    my $site_host = $config->{site}{$siteName}{database}{host};
    my $site_name = $config->{site}{$siteName}{database}{name};
    my $site_username = $config->{site}{$siteName}{database}{username};
    my $site_password = $config->{site}{$siteName}{database}{password};

    my $mysql_console = `which mysql`;
    chomp $mysql_console;
    unless($mysql_console) {
        $mysql_console = ask($ASK_TEXTDEF, "mysql console is not in PATH, can you locate it for me?", '/usr/local/mysql/bin/mysql');
        unless(-f $mysql_console) {
            print "There was no mysql console at $mysql_console. Cancelling.\n\n";
            return;
        }
    }
    print "We need a mysql user that is able to create databases and users, this user is usually named root.\n";
    my $mysql_user =    ask($ASK_TEXTDEF, "Mysql user name with privileges to create databases users and tables?", "root");
    my $need_pwd =        ask($ASK_LISTDEF, "Do you need a password to connect with this user?", "no", "yes");
    my $mysql_pwd;
    if($need_pwd =~ /YES/i) {
        my $noecho =     ask($ASK_LISTDEF, "Do you want me to turn of echo while you type in this password?");
        if($noecho =~ /YES/i) {
            $mysql_pwd = ask($ASK_PASSWD, "Please enter password for mysql user $mysql_user\@$site_host: ");
        } else {
            $mysql_pwd = ask($ASK_TEXT,   "Please enter password for mysql user $mysql_user\@$site_host: ");
        }
    }
    print "OK!\n\n";

    print "Creating database $site_name...\n";    
    my $M  = "$mysql_console --host=\"$site_host\" --user=\"$mysql_user\"";
       $M .= " --password=\"$mysql_pwd\"" if $mysql_pwd;
    my $create_db_q        = "CREATE DATABASE IF NOT EXISTS $site_name";
    my $syscmd = "echo \"$create_db_q\" | $M";
    print "% $syscmd\n";
    my $sysret = `$syscmd`;

    print "Creating database user $site_username...\n";
    my $create_user_q    = "CREATE USER $site_username IDENTIFIED BY '$site_password';";
    $syscmd = "echo \"$create_user_q\" | $M";
    print "% $syscmd\n";
    $sysret = `$syscmd`;

    print "Granting privileges for $site_name to $site_username...\n";
    my $grant_q    = "GRANT ALL PRIVILEGES ON $site_name.* TO \'$site_username'\@'$site_host' IDENTIFIED BY '$site_password';";
    $syscmd = "echo \"$grant_q\" | $M";
    print "% $syscmd\n";
    $sysret = `$syscmd`;
    
    my $sqldist = './sql';
    unless(-f "$sqldist/01-Users.sql") {
        print "Can't find sql template files. Are you running this program from the Modwheel distribution directory?\n";
        print "Please locate the directory containing the SQL files. (Usually Modwheel-0.1/sql/)\n";
        $sqldist = ask($ASK_TEXTDEF, "Enter the directory containing the modwheel SQL templates", "./sql");
        unless(-f "$sqldist/01-Users.sql") {
            print "Couldn't find the sql files at the directory you specified. Please run this script from the same place you ran 'perl Makefile.pl'\n";
            return undef;
        }
    }

    $M .= " $site_name";
    foreach my $sqlfile (qw(01-Users.sql 02-Tags.sql 03-Object.sql 04-Repository.sql mytags.sql))
    {
        print "Creating table $sqlfile...\n";
        $syscmd = "$M < $sqldist/$sqlfile";
        print "% $syscmd\n";
        $sysret = `$syscmd`;
    }
}    

sub ask
{
    my($t, $question, $default_answer, @suggestions) = @_;
    return undef unless $question;
    unshift @suggestions, $default_answer if $default_answer;
    my $complete = [ ];
    if($t == $ASK_LISTDEF || $t == $ASK_LIST) {
        @suggestions    = ('Yes', 'No') unless scalar @suggestions;
        $default_answer ||= 'Yes';

        for(my $i=0; $i < @suggestions; $i++) {
            foreach((lc($suggestions[$i]), $suggestions[$i], uc($suggestions[$i]))) {
                push(@$complete, $_)
            }
            if($t == $ASK_LISTDEF && $suggestions[$i] eq $default_answer) {
                $suggestions[$i] = $Bold. uc($default_answer). $Reset
            }
        }
    }
    
    my $suggest = join('/', @suggestions);
    my $answer;
    while(1) {
        my $prompt = "$Bold$question$Reset";
        $prompt   .= " [$suggest]: " if $suggest;

        # Get the answer...
        if($t == $ASK_PASSWD) {
            print $prompt;
            ReadMode('noecho');
            $answer = <STDIN>;
            ReadMode('restore');
            chomp $answer;
            print "\n";
        }
        else {
            $answer = Complete("$Bold$question$Reset [$suggest]: ", $complete);
        }

        # ... then check if the answer conforms to  our type.
        if(   $t == $ASK_DEFAULT) {
            return $answer ? $answer : $default_answer;
        }
        elsif($t == $ASK_LISTDEF) {
            return $default_answer unless $answer;
            if(grep /$answer/i, @$complete) {
                return $answer;
            } else {
                print "Please enter one of the following: ", join(", ", @suggestions), ". Or just hit enter for $default_answer\n";
            }
        }    
        elsif($t == $ASK_LIST) {
            if(grep /$answer/i, @$complete) {
                return $answer
            } else {
                print "Please enter one of the following: ", join(", ", @suggestions), ".\n";
            }
        }
        elsif($t == $ASK_NUMBER) {
            $answer =~ /(\d+)/;
            if($1) {
                $answer = $1;
                return;
            } else {
                print "Your answer is not a number.\n"
            }
        }
        elsif($t == $ASK_TEXT) {
            print "$answer\n";
            return $answer if $answer;
            print "Please enter your answer.\n";
        }
        elsif($t == $ASK_TEXTDEF) {
            return $answer ? $answer : $default_answer
        }
        elsif($t == $ASK_PASSWD) {
            return $answer if $answer;
        }
    }            

    return $answer;
}

sub write_apache_config
{
my($toFile, $adminSiteName, $userSiteName) = @_;
my $Arep    = $config->{site}{$adminSiteName}{repository};
my $Arepurl = $config->{site}{$adminSiteName}{repositoryurl};
my $Atdir   = $config->{site}{$adminSiteName}{templatedir};
my $Urep    = $config->{site}{$userSiteName}{repository};
my $Urepurl = $config->{site}{$userSiteName}{repositoryurl};
my $Utdir   = $config->{site}{$userSiteName}{templatedir};
$Arepurl =~ s/^\///;
$Urepurl =~ s/^\///;
#my $
open(APCONF, ">$toFile") or die("Couldn't open $toFile: $!\n");
print APCONF qq{

<IfModule perl_module>
    NameVirtualHost *:80
    <VirtualHost *:80>
    ServerName admin.localhost
    ErrorLog logs/error_log
    <Location />
        SetHandler perl-script                                                                                                            
        PerlAuthenHandler   Modwheel::Apache2::Authen                                                                                     
        PerlResponseHandler Modwheel::Apache2                                                                                             
        PerlSetVar ModwheelPrefix       $prefix
        PerlSetVar ModwheelConfigFile   config/modwheelconfig.yml                                                                         
        PerlSetVar ModwheelSite         $adminSiteName
        PerlSetVar ModwheelFileUploads  Yes                                                                                               
        PerlSetVar Locale               en_EN                                                                                             
        PerlSetVar DontHandle           "$Arepurl javascript css images scriptaculous"                                                         
                                                                                                                                          
        AuthType Basic                                                                                                                    
        AuthName "void"                                                                                                                   
        Require valid-user                                                                                                                
    </Location>                                                                                                                           
    Alias $Arepurl $Arep
    Alias /css $Atdir/css                                                                              
    Alias /javascript $Atdir/javascript                                                                
    Alias /scriptaculous $Atdir/Scriptaculous                                                                      
    <Directory $Arep/*/*>                                                                                        
        Order Deny,Allow                                                                                                                  
        Allow from all                                                                                                                    
    </Directory>                                                                                                                          
    <Directory $Atdir/*/*>                                                                                         
        Order Deny,Allow                                                                                                                  
        Allow from all                                                                                                                    
    </Directory>                                                                                                                          
</VirtualHost>
<VirtualHost *:80>                                                                                                                        
    ServerName localhost                                                                                                                  
    ErrorLog logs/error_log                                                                                                               
    <Location />                                                                                                                          
        SetHandler perl-script                                                                                                            
        PerlResponseHandler Modwheel::Apache2                                                                                             
        PerlSetVar ModwheelPrefix       $prefix
        PerlSetVar ModwheelConfigFile   config/modwheelconfig.yml                                                                         
        PerlSetVar ModwheelSite         $userSiteName
        PerlSetVar ModwheelFileUploads  No                                                                                                
        PerlSetVar ModwheelWebPathToId  Yes                                                                                               
        PerlSetVar Locale               en_EN                                                                                             
        PerlSetVar DontHandle           "$Urepurl javascript css images scriptaculous"                                                         
    </Location>                                                                                                                           
    Alias $Urepurl $Urep
    Alias /css $Utdir/css                                                                              
    Alias /javascript $Utdir/javascript                                                                
    Alias /scriptaculous $Utdir/Scriptaculous                                                                      
    <Directory $Urep/*/*>                                                                                        
        Order Deny,Allow                                                                                                                  
        Allow from all                                                                                                                    
    </Directory>                                                                                                                          
    <Directory $Utdir/*/*>                                                                                         
        Order Deny,Allow                                                                                                                  
        Allow from all                                                                                                                    
    </Directory>                                                                                                                          
</VirtualHost>

</IfModule>
};
close(APCONF);
}
