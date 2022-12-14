# LexicO-scripts
This repository contains a collection of scripts (Perl and MySQL) used for automatic discovery, marking and removing of candidate redundant entries in the Parole-Simple-Clips computational lexicon in order to create LexicO computational lexicon.

You can find the prepared resource [here](https://dspace-clarin-it.ilc.cnr.it/repository/xmlui/handle/20.500.11752/ILC-977)

## Requirements
* MySQL Server and Client (version >= 5.6)
* Perl
* Perl Config::Simple (```cpan install Config::Simple.pm```)
* Perl DBI (```cpan install DBI```)
* Perl Getopt::Std (```cpan install Getopt::Std```)

## Steps to create the LexicO lexicon

1. First of all, download the PSC lexicon hosted at the Clarin-IT Repository [Download](https://dspace-clarin-it.ilc.cnr.it/repository/xmlui/bitstream/handle/20.500.11752/ILC-88/simplelexicon.sql.tar.gz?sequence=1&isAllowed=y)
2. Import the downloaded dump in a MySQL server.
```
$ tar xzf simplelexicon.sql.tar.gz | mysql -u USER -p < simplelexicon.sql
```
3. After cloning the repository move to the LexicO-scripts directory 
 ```
 cd Lexico-scripts
 ```
4. Create the configuration file from the stub<br>
```
$ cp app-stub.cfg app.cfg
```
5. Customize the app.cfg file with the proper values. In particular set the right value for ```dsn```, ```username``` and ```password```. Do not modify other variables.
```
$ vim app.cfg
```
6. Create redundant tables
```
$ mysql -v -v -u USER -p simplelexicon < 01_Create_Redundant_Tables.sql
```
7. Discover rendundant Phonological Entries
```
$ perl redundantPhu.pl
```
8. Discover rendundant Semantic Entries
```
$ perl redundantUsemUsyns.pl -a usem
```
9. Discover rendundant Syntactic Entries
```
$ perl redundantUsemUsyns.pl -a usyn
```
10. Discover rendundant Morphological Entries
```
$ mysql -v -v -u USER -p simplelexicon < 02_Redundant_Morphological_Entries.sql
```
11. Updating tables
```
$ mysql -v -v -u USER -p simplelexicon < 03_Update_Tables.sql
```
12. Discover and update redundant and missing associations
```
$ mysql -v -v -u USER -p simplelexicon < 04_Redundant_Missing_Associations.sql
```
