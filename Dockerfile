FROM php:7.2-apache

RUN apt-get update
RUN apt-get install -y libpng-dev
RUN docker-php-ext-install gd
RUN apt-get install -y libgd-gd2-perl
RUN apt-get install -y python
RUN cpan install Config::IniFiles
RUN cpan install GD::Arrow

COPY ./ /var/www/html/

# Make sure that the "temp" dir exists:
RUN mkdir ./temp
RUN mkdir ./temp/images

# Make sure that apache/php can write (gff and png files) to the temp directory:
RUN chown -R www-data:www-data /var/www/html/temp

# On Redhat
# yum update
# yum install libpng-devel
#yum install gd-devel
#yum install perl-GD
# yum install perl-CPAN