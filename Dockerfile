# taking image from docker hub
FROM store/intersystems/iris-community:2020.1.0.199.0

#setting user name on root
USER root

# setting work directory
WORKDIR /opt/mockfw
# changing ownership of the file
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/mockfw

#setting user name
USER irisowner

# copy files
COPY  Installer.cls .
COPY  src src
COPY irissession.sh /
# change shell to do objectsript commands
SHELL ["/irissession.sh"]

# launch Installer in iris shell
RUN \ 
  do $SYSTEM.OBJ.Load("Installer.cls", "ck") \
  set sc = ##class(App.Installer).setup() 

# bringing the standard shell back
SHELL ["/bin/bash", "-c"]

