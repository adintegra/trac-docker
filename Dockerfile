FROM ubuntu:bionic
MAINTAINER = Di Xu <stephenhsu90@gmail.com>
ENV TRAC_ADMIN_NAME trac_admin
ENV TRAC_ADMIN_PASSWD passw0rd
ENV TRAC_PROJECT_NAME trac_project
ENV TRAC_DIR /var/local/trac
ENV TRAC_INI $TRAC_DIR/conf/trac.ini
ENV DB_LINK sqlite:db/trac.db
EXPOSE 8123

# Ubuntu 20
# Not fully functional, as v3 of Python is now standard - ymmv
# RUN apt-get update
# RUN apt-get --assume-yes install software-properties-common
# RUN add-apt-repository universe
# RUN apt-get update
# RUN apt-get install --assume-yes python2 curl
# RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
# RUN python2 get-pip.py

# Ubuntu 18
ENV TZ=Europe/Zurich
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y trac python-babel \
   libapache2-mod-wsgi python-pip && apt-get -y clean
RUN pip install --upgrade Babel Trac
RUN mkdir -p $TRAC_DIR
RUN trac-admin $TRAC_DIR initenv $TRAC_PROJECT_NAME $DB_LINK
RUN trac-admin $TRAC_DIR deploy /tmp/deploy
RUN mv /tmp/deploy/* $TRAC_DIR
RUN htpasswd -b -c $TRAC_DIR/.htpasswd $TRAC_ADMIN_NAME $TRAC_ADMIN_PASSWD
RUN trac-admin $TRAC_DIR permission add $TRAC_ADMIN_NAME TRAC_ADMIN
RUN chown -R www-data: $TRAC_DIR
RUN chmod -R 775 $TRAC_DIR
RUN echo "Listen 8123" >> /etc/apache2/ports.conf
ADD trac.conf /etc/apache2/sites-available/trac.conf
RUN sed -i 's|$AUTH_NAME|'"$TRAC_PROJECT_NAME"'|g' /etc/apache2/sites-available/trac.conf
RUN sed -i 's|$TRAC_DIR|'"$TRAC_DIR"'|g' /etc/apache2/sites-available/trac.conf
RUN a2dissite 000-default && a2ensite trac.conf
CMD service apache2 stop && apache2ctl -D FOREGROUND
