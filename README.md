# daytrader7-fips-env-setup
For setup and start the daytrader7 in OpenLiberty using the OpenJDK FIPS mode.

Install OpenSSL and Maven.

    yum instll maven
    yum install openssl
   
Enable FIPS on Redhat and reboot using "root" access  .
   
    fips-mode-setup --enable
    reboot

Check if OS in FIPS mode by the following command.

    fips-mode-setup --check

Steps to start the daytrader7 in OpenLiberty using the OpenJDK FIPS mode.
    
    export JAVA_HOME=<java home path> 
    git clone https://github.com/taoliult/daytrader7-fips-env-setup.git  
    cd daytrader7-fips-env-setup
    ./setup.sh
    
The daytrader7 will started in OpenLiberty using the OpenJDK FIPS mode.

Access HTTPS by:
    
    https://<IP Address>:9443/daytrader/

Noted:

If there is logging issue during the Maven install, please remove the commons-logging.jar from /usr/share/maven/lib.

If running on RHEL 9.2, please change from nssSecmodDirectory = /etc/pki/nssdb to nssSecmodDirectory = sql:/etc/pki/nssdb in nss.fips.cfg
