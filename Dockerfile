FROM erlang:19.2.3
MAINTAINER Heinz N. Gies <heinz@project-fifo.net>

###################
##
## Get DalmatinerFE
##
###################

ENV DDB_VSN=0.3.1p1
ENV DDB_PATH=/dalmatinerdb
ENV DDB_REF=$DDB_VSN

RUN cd / \
    && env GIT_SSL_NO_VERIFY=true git clone -b $DDB_VSN http://github.com/dalmatinerdb/dalmatinerdb.git dalmatinerdb.git

RUN cd dalmatinerdb.git \
    && env GIT_SSL_NO_VERIFY=true git checkout $DDB_REF \
    && make rel \
    && mv /dalmatinerdb.git/_build/prod/rel/ddb $DDB_PATH \
    && rm -rf /dalmatinerdb.git \
    && rm -rf $DDB_PATH/lib/*/c_src

RUN mkdir -p /data/dalmatinerdb/etc \
    && mkdir -p /data/dalmatinerdb/db \
    && mkdir -p /data/dalmatinerdb/log \
    && cp $DDB_PATH/etc/dalmatinerdb.conf.example /data/dalmatinerdb/etc/dalmatinerdb.conf \
    && sed -i -e '/RUNNER_USER=dalmatiner/d' $DDB_PATH/bin/ddb \
    && sed -i -e '/RUNNER_USER=dalmatiner/d' $DDB_PATH/bin/ddb-admin

COPY ddb.sh /

EXPOSE 5555

ENTRYPOINT ["/ddb.sh"]
