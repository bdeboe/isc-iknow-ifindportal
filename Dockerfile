FROM store/intersystems/iris-community:2020.4.0.547.0

USER root

ENV SRC_DIR=/home/irisowner

RUN mkdir /home/irisowner/code

COPY --chown=irisowner src/ /home/irisowner/code/

USER irisowner

RUN iris start $ISC_PACKAGE_INSTANCENAME && \
     /bin/echo -e " do \$system.OBJ.ImportDir(\"/home/irisowner/code/\",,\"c\",,1)\n" \
     "SET sc = ##class(Demo.Hotels.Review).%BuildIndices()\n" \
     "IF sc=1 {WRITE !,\"Successful index build\" }\n" \
            " halt" \
    | iris session $ISC_PACKAGE_INSTANCENAME && \
    iris stop $ISC_PACKAGE_INSTANCENAME quietly

HEALTHCHECK --interval=5s CMD /irisHealth.sh || exit 1