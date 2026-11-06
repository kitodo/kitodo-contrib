# create-project.pl
#
# Create an Eclipse project to develop Kitodo.Production on Windows
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;
use Cwd qw(getcwd);
use File::Find;
local $/ = undef;

### Config ###

# Java version

# Hint: If you experience "could not transfer from central ... peer not
# authenticated" the SSH certificates have changed, and you need to download
# a newer JDK. --> https://adoptium.net/de/temurin/releases

# locally redefine JAVA_HOME when working with 3.x branches
$ENV{JAVA_HOME} = 'C:\Software\Java\jdk-11.0.32.1+1';

# Workspace path

# Workspace to copy. Leave this commented-out first, and run the script to
# create a base workspace (perl create-project.pl _create_workspace).
# Configure that workspace to your needs needs (add projects, configure line
# endings (unix), code formatter, organize imports, checkstyle, JDK, Tomcat...
# Then reference this workspace here.
#my $copy_workspace_path_fs; # = "/C/Users/your.username/...path-to.../_create_workspace";

# GitHub credentials

#my $fullname = "Max Mustermann";        # first and last name
#my $contact = "max.mustermann\@example.de"; # e-mail address
my $uname = "user-name";                # user name on GitHub.com
my $tok = "ghp_abcdefghijklmnopqrstuvwxyzABCD012345"; # personal access token

# Database

my $db_exe = "mariadb";                 # database client
my $db_admin = "root";                  # database admin, can create databases
my $db_password = "einfach";            # database admin password


### Usage ###

die "\nUsage: create-project.pl ‹path› [[‹fork›] ‹branch›]\n\n".
  "   path: subfolder to check out to, can be a path separated by \\ or /\n".
  "   fork: from which user fork the branch should be fetched (usually \"".
  "kitodo\")\n   branch: which branch to fetch from GitHub (usually \"main\")".
  "\n\n   Examples:\n".
  "      perl create-project.pl kitodev\\issue-1234\n".
  "      perl create-project.pl kitodev/issue-123 2.x\n".
  "      perl create-project.pl kitodev\\patch-123456 my-user patch-123456\n"
  unless scalar(@ARGV) >= 1 and scalar(@ARGV) <= 4;
my $debug = (scalar(@ARGV) >= 4);

die "‹path› must be relative" if ($ARGV[0] =~ m/^[A-Za-z]:\\/);
die "‹path› must be in this directory" if ($ARGV[0] =~ m/^\.\./);
die "‹path› must be at least two segments long" unless ($ARGV[0] =~ m/[\/\\]/);


### Program ###

# create different paths
my $script_path_fs = getcwd();          # script path in forward-slash notation

my $script_path_win                     # script path in Windows
  = $script_path_fs =~ s/^\/([c-z])\//$1:\\/r;
  $script_path_win =~ s/\//\\/g;

my $script_path_win_esc                 # script path in Windows with doubled
  = $script_path_win."\\";            # backslashes
  $script_path_win_esc =~ s/\\/\\\\/g;

my $target_segmented                    # target folder, segmented (by ";")
  = $ARGV[0] =~ s/[\/\\]/;/gr;

my $target_fs                           # target folder with forward slashes
  = $target_segmented =~ s/;/\//gr;

my $target_win                          # target folder in Windows
  = $target_segmented =~ s/;/\\/gr;

my $target_win_esc = $target_win."\\";  # target folder in Windows with doubled
 $target_win_esc =~ s/\\/\\\\/g;        # and terminal backslash

my $code_path                           # path to the source code
 = $script_path_win_esc.$target_win_esc."kitodo-production";

my $workdir_path                        # path to the working directory
  = $script_path_win_esc.$target_win_esc."kitodo-var";

my $git_dir = $code_path =~ s/:/\\:/r;  # path to the .git directory
 $git_dir = $git_dir."\\\\.git";

my $db_name                             # name of database scheme to use
  = $target_segmented =~ s/[^0-9;A-Za-z]//gr;
  $db_name =~ s/;/_/g;
  $db_name = "kitodo_" . lc $db_name ;

my $fork = scalar(@ARGV) >= 3 ? $ARGV[1] : "kitodo" ;
my $clone_url = "https://github.com/$fork/kitodo-production/";
my $branch_arg = $#ARGV;
$branch_arg = 2 if ($branch_arg > 2);
my $branch = scalar(@ARGV) > 1 ? $ARGV[$branch_arg] : "main" ;
my $branch_to = $branch eq "main" ? $target_segmented =~ s/^.*;//gr : $branch;

if($debug){
  print "\n\$script_path_fs\t$script_path_fs\n";
  print "\$script_path_win\t$script_path_win\n";
  print "\$script_path_win_esc\t$script_path_win_esc\n\n";
  print "\$target_segmented\t$target_segmented\n";
  print "\$target_fs\t$target_fs\n";
  print "\$target_win\t$target_win\n";
  print "\$target_win_esc\t$target_win_esc\n\n";
  print "\$code_path\t$code_path\n";
  print "\$workdir_path\t$workdir_path\n";
  print "\$git_dir\t$git_dir\n\n";
  print "\$db_name\t$db_name\n\n";
  print "\$fork\t$fork\n";
  print "\$clone_url\t$clone_url\n";
  print "\$branch\t$branch\n";
  print "\$branch_to\t$branch_to\n\n";
}

# create directory
system("mkdir", "-p", $target_fs);

# clone from GitHub
chdir "$target_win";
system("git", "clone", "--single-branch", "--branch", $branch, $clone_url);

# Fix "path must include project and resource name"
# see https://github.com/kitodo/kitodo-production/pull/6366
open IN, "< kitodo-production/Kitodo/pom.xml";
  my $kito_pom = <IN>;
  close IN;
$kito_pom =~ s/>..\/c/>\${maven.multiModuleProjectDirectory}\/c/;
open(OUT, "> kitodo-production/Kitodo/pom.xml");
  print OUT $kito_pom;
  close(OUT);
system("git", "update-index", "--assume-unchanged",
  "kitodo-production/Kitodo/pom.xml");

open IN, "< kitodo-production/Kitodo-DataManagement/pom.xml";
  my $data_pom = <IN>;
  close IN;
$data_pom =~ s/>..\/c/>\${maven.multiModuleProjectDirectory}\/c/;
open(OUT, "> kitodo-production/Kitodo-DataManagement/pom.xml");
  print OUT $data_pom;
  close(OUT);
system("git", "update-index", "--assume-unchanged",
  "kitodo-production/Kitodo-DataManagement/pom.xml");

# set git dir
open IN, "< .metadata\\.plugins\\org.eclipse.core.runtime\\.settings\\org.eclipse.egit.core.prefs";
  my $oeecp = <IN>;
  close IN;
$oeecp =~ s/^GitRepositoriesView.GitDirectories=.*$/GitRepositoriesView.GitDirectories=$git_dir/m;
open(OUT, "> .metadata\\.plugins\\org.eclipse.core.runtime\\.settings\\org.eclipse.egit.core.prefs");
  print OUT $oeecp;
  close(OUT);

# copy Eclipse workspace files
chdir $script_path_fs;
system("sh", "-c", "cp -Rv _create_project/* $target_fs/");

# configure git
chdir "$target_win\\kitodo-production";
system("git", "config", "user.name", $fullname);
system("git", "config", "user.email", $contact);
system("git", "remote", "rename", "origin", $fork);
system("git", "checkout", "-b", $branch_to) unless $branch eq $branch_to;

if($uname eq $fork) {
    # set credentials for origin
    system("git", "remote", "set-url", $fork,
        "https://$uname:$tok\@github.com/$uname/kitodo-production.git");
    # add upstream
    system("git", "remote", "add", "kitodo",
        "https://github.com/kitodo/kitodo-production.git");
} else {
    # add origin with credentials
    system("git", "remote", "add", $uname,
        "https://$uname:$tok\@github.com/$uname/kitodo-production.git");
}

open(OUT, ">> .git/info/exclude");
  print OUT "**/.classpath\n";
  print OUT "**/.project\n";
  print OUT "**/.settings\n";
  close(OUT);

# configure hibernate
open IN, "< Kitodo/src/main/resources/hibernate.cfg.xml";
  my $hicx = <IN>;
  close IN;
$hicx =~ s/\/kitodo\?/\/$db_name\?/;
open(OUT, "> Kitodo/src/main/resources/hibernate.cfg.xml");
open(OUT, "> config-local/hibernate.cfg.xml");
  print OUT $hicx;
  close(OUT);
system("sh", "-c", "cp config-local/hibernate.cfg.xml Kitodo/src/main/resources/");
system("git", "update-index", "--assume-unchanged",
  "Kitodo/src/main/resources/hibernate.cfg.xml");

# configure kitodo
open IN, "< Kitodo/src/main/resources/kitodo_config.properties";
  my $cp = <IN>;
  close IN;
$cp =~ s/^directory.config.*?$/directory.config=$code_path\\\\Kitodo\\\\src\\\\main\\\\resources\\\\/m;
$cp =~ s/^directory.rulesets.*?$/directory.rulesets=$workdir_path\\\\rulesets\\\\/m;
$cp =~ s/^directory.xslt.*?$/directory.xslt=$workdir_path\\\\xslt\\\\/m;
$cp =~ s/^directory.metadata.*?$/directory.metadata=$workdir_path\\\\metadata\\\\/m;
$cp =~ s/^directory.users.*?$/directory.users=$workdir_path\\\\users\\\\/m;
$cp =~ s/^directory.temp.*?$/directory.temp=$workdir_path\\\\temp\\\\/m;
$cp =~ s/^directory.diagrams.*?$/directory.diagrams=$workdir_path\\\\diagrams\\\\/m;
$cp =~ s/^directory.modules.*?$/directory.modules=$workdir_path\\\\modules\\\\/m;
$cp =~ s/^directory.debug.*?$/directory.debug=$workdir_path\\\\debug\\\\/m;
$cp =~ s/^directory.diagrams.*?$/directory.diagrams=$workdir_path\\\\diagrams\\\\/m;
$cp =~ s/^directory.diagrams.*?$/directory.diagrams=$workdir_path\\\\diagrams\\\\/m;
$cp =~ s/^ocrd.workflows.directory.*?$/ocrd.workflows.directory=$workdir_path\\\\ocrd_workflows\\\\/m;
# TODO: variable.xyz
$cp =~ s/^script_createDirUserHome.*?$/script_createDirUserHome=$workdir_path\\\\scripts\\\\script_createDirUserHome.bat/m;
$cp =~ s/^script_createDirMeta.*?$/script_createDirMeta=$workdir_path\\\\scripts\\\\script_createDirMeta.bat/m;
$cp =~ s/^script_createSymLink.*?$/script_createSymLink=$workdir_path\\\\scripts\\\\script_createSymLink.bat/m;
$cp =~ s/^script_deleteSymLink.*?$/script_deleteSymLink=$workdir_path\\\\scripts\\\\script_deleteSymLink.bat/m;
open(OUT, "> config-local/kitodo_config.properties");
  print OUT $cp;
  close(OUT);
open(OUT, "> Kitodo/src/main/resources/kitodo_config.properties");
  print OUT $cp;
  close(OUT);
system("git", "update-index", "--assume-unchanged",
  "Kitodo/src/main/resources/kitodo_config.properties");

# configure log4j2
open(OUT, "> config-local/log4j2.xml");
  print OUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
  print OUT "<Configuration monitorInterval=\"60\">\n";
  print OUT "    <Appenders>\n";
  print OUT "        <Console name=\"STDOUT\" target=\"SYSTEM_OUT\">\n";
  print OUT "        <PatternLayout pattern=\"[%-5level] %d{yyyy-MM-dd ".
                            "HH:mm:ss.SSS} [%t] %c{1} - %msg%n\"/>\n";
  print OUT "        </Console>\n";
  print OUT "    </Appenders>\n";
  print OUT "    <Loggers>\n";
  print OUT "        <Logger name=\"org.kitodo\" level=\"debug\" ".
                            "additivity=\"false\">\n";
  print OUT "            <AppenderRef ref=\"STDOUT\"/>\n";
  print OUT "        </Logger>\n";
  print OUT "        <Root level=\"error\">\n";
  print OUT "            <AppenderRef ref=\"STDOUT\"/>\n";
  print OUT "        </Root>\n";
  print OUT "    </Loggers>\n";
  print OUT "</Configuration>\n";
  close(OUT);
system("sh", "-c", "cp config-local/log4j2.xml Kitodo/src/main/resources/");
system("git", "update-index", "--assume-unchanged",
  "Kitodo/src/main/resources/log4j2.xml");

# build
system("mvn.cmd", "clean", "install"); # fails building Kitodo - Core, that's OK.

# create database
system($db_exe, "-u$db_admin", "-p$db_password", "-e",
  "CREATE DATABASE $db_name;GRANT ALL PRIVILEGES ON $db_name.* ".
  "TO kitodo\@localhost IDENTIFIED BY 'kitodo';");
  
# load data
system($db_exe, "-u$db_admin", "-p$db_password", "-D$db_name",
  "--default-character-set=UTF8", "-e", "SOURCE Kitodo/setup/schema.sql; ".
  "SOURCE Kitodo/setup/default.sql;");

# database migration
chdir "Kitodo-DataManagement";
open IN, "< src/main/resources/db/config/flyway.properties";
  my $fwp = <IN>;
  close IN;
$fwp =~ s/\/kitodo\?/\/$db_name\?/;
open(OUT, "> src/main/resources/db/config/flyway.properties");
  print OUT $fwp;
  close(OUT);
system("mvn.cmd", "clean", "install", "-Pflyway");
system("git", "restore", "src/main/resources/db/config/flyway.properties");

# give testAdmin all permissions
system($db_exe, "-u$db_admin", "-p$db_password", "-D$db_name", "-e", 
  "INSERT INTO role (title, client_id) VALUES ('Almighty', 1);".
  "SET \@Almighty := last_insert_id();".
  "INSERT INTO role_x_authority SELECT \@Almighty, id FROM authority;".
  "INSERT INTO user_x_role SELECT \@Almighty, id FROM user WHERE login = 'testAdmin';");

# copy workspace
if (defined $copy_workspace_path_fs) {
    print "Copying $copy_workspace_path_fs to $script_path_fs/$target_fs ...\n";
    system("sh", "-c", "cp -a --no-clobber \"$copy_workspace_path_fs/.\" \"$script_path_fs/$target_fs\"");
}
