# Start
# git clone https://github.com/taoliult/daytrader7-fips-env-setup.git

# For Generate and Import the RSA and EC Keys
cd certs

# For RSA Key
openssl genrsa -out root.key 2048
openssl req -x509 -new -nodes -key root.key -days 365 \
-config root.cnf -out root.crt

openssl genrsa -out server-rsa.key 2048
openssl req -new -key server-rsa.key -config server.cnf \
-out server-rsa.csr

openssl genrsa -out intermediate.key 2048
openssl req -new -key intermediate.key \
-config intermediate.cnf -out intermediate.csr

openssl x509 -req -days 365 -in intermediate.csr \
-CA root.crt -CAkey root.key -CAserial root.srl -CAcreateserial \
-extfile root.cnf -extensions intermediate_ext -out intermediate.crt

openssl x509 -req -days 365 -in server-rsa.csr \
-CA intermediate.crt -CAkey intermediate.key \
-CAserial intermediate.srl -CAcreateserial \
-extfile intermediate.cnf -extensions server_ext -out server-rsa.crt

cat root.crt intermediate.crt > cachain.crt

openssl pkcs12 -export -chain -in server-rsa.crt -inkey server-rsa.key \
-name server-rsa -CAfile cachain.crt -out keystore-rsa.p12  \
-passout pass:changeit

# For EC Key
openssl ecparam -name prime256v1 -genkey -noout -out server-ec.key
openssl req -new -key server-ec.key -config server.cnf \
-out server-ec.csr

openssl x509 -req -days 365 -in server-ec.csr \
-CA intermediate.crt -CAkey intermediate.key \
-CAserial intermediate.srl -CAcreateserial \
-extfile intermediate.cnf -extensions server_ext -out server-ec.crt

openssl pkcs12 -export -chain -in server-ec.crt -inkey server-ec.key \
-name server-ec -CAfile cachain.crt -out keystore-ec.p12  \
-passout pass:changeit

# Import RSA and EC Keys into NSSDB
pk12util -i keystore-rsa.p12 -W changeit -d /etc/pki/nssdb
pk12util -i keystore-ec.p12 -W changeit -d /etc/pki/nssdb

# Clone Daytrader7
cd ..
git clone https://github.com/WASdev/sample.daytrader7.git

# Install Daytrader7
cd sample.daytrader7
mvn install
cd daytrader-ee7
mvn liberty:create
mvn liberty:deploy

# Update the Liberty server.xml File
sed -i 's/<\/server>/<featureManager><feature>transportSecurity-1.0<\/feature><\/featureManager><sslDefault sslRef="mySSLSettings" \/><ssl id="mySSLSettings" keyStoreRef="daytrader7" sslProtocol="TLSv1.2" \/><keyStore id="daytrader7" location="currentPWD\/..\/..\/certs\/pkcs11cfg.cfg" type="PKCS11-NSS-FIPS" fileBased="false" password="changeit" provider="SunPKCS11-NSS-FIPS" \/><\/server>/g' target/liberty/wlp/usr/servers/defaultServer/server.xml
sed -i "s|currentPWD|$PWD|g" target/liberty/wlp/usr/servers/defaultServer/server.xml

# Install Liberty Features
mvn liberty:install-feature

# Add FIPS JVM property into jvm.options
echo "-Dsemeru.fips=true" >> target/liberty/wlp/usr/servers/defaultServer/jvm.options
echo "-Djava.security.debug=semerufips" >> target/liberty/wlp/usr/servers/defaultServer/jvm.options

# Update the bootstrap.properties
echo "com.ibm.ws.logging.trace.specification=*=event=enabled:\\" >> target/liberty/wlp/usr/servers/defaultServer/bootstrap.properties
echo "logservice=all=enabled:\\" >> target/liberty/wlp/usr/servers/defaultServer/bootstrap.properties
echo "com.ibm.websphere.ssl.*=all=enabled:\\" >> target/liberty/wlp/usr/servers/defaultServer/bootstrap.properties
echo "com.ibm.wsspi.ssl.*=all=enabled:\\" >> target/liberty/wlp/usr/servers/defaultServer/bootstrap.properties
echo "com.ibm.ws.ssl.*=all=enabled" >> target/liberty/wlp/usr/servers/defaultServer/bootstrap.properties

# Start the Daytrader in OpenJDK FIPS Mode
target/liberty/wlp/bin/server start defaultServer

# s_client to make sure the port 9443 is up
openssl s_client -connect $HOSTNAME:9443 -tlsextdebug -showcerts | tee ../../logs/s_client_output.log

# Stop the Daytrader
target/liberty/wlp/bin/server stop defaultServer

# Collect the logs
cp target/liberty/wlp/usr/servers/defaultServer/logs/console* ../../logs/
cp target/liberty/wlp/usr/servers/defaultServer/logs/messages* ../../logs/
cp target/liberty/wlp/usr/servers/defaultServer/logs/trace* ../../logs/

# The End
