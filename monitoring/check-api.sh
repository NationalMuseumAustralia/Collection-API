#/bin/bash
# to install mail subsystem, use this command:
# sudo apt-get install libnet-ssleay-perl libcrypt-ssleay-perl sendemail libio-socket-ssl-perl exim4
# to configure exim4 MTA:
# sudo dpkg-reconfigure exim4-config
host=$1
from="nma-api-monitor@oceania.digital"
to="conal.tuohy+nma-api-monitor@gmail.com api@nma.gov.au"
url="https://$host/status"
if [ -f $host.txt ]; then
	current_status="up"
else
	current_status="down"
fi
echo "API status was previously $current_status"

# download from url into 'result' file, and record http response code
response_code=$(curl -s -i -o $host.txt -w "%{response_code}" "$url" )
echo "API new response code is $response_code"

# if current API status is "down" then notify only if status is now "up"
# or if current API status is "up", then notify only if status is now "down"
if [ $response_code = "200" ] && [ $current_status = "down" ]; then
	echo "API has come back up"
	sendemail -f $from -t $to -u "API up on $host" -m "$url returned $response_code"
fi
if [ $response_code != '200' ]; then
	if [ $current_status = "up" ]; then
		echo "API has gone down"
		sendemail -f $from -t $to -u "API down on $host" -m "$url returned $response_code" -a $host.txt
		# remove API result file (semaphore) to signal that the API is now down
	fi
	rm $host.txt
fi
