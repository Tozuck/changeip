#!/bin/bash

echo_info() {
  echo -e "\033[1;32m[INFO]\033[0m $1"
}
echo_error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
  exit 1
}

apt-get update; apt-get install curl socat git nload speedtest-cli -y

if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | sh || echo_error "Docker installation failed."
else
  echo_info "Docker is already installed."
fi

rm -r Marzban-node

git clone https://github.com/Gozargah/Marzban-node

rm -r /var/lib/marzban-node

mkdir /var/lib/marzban-node

rm ~/Marzban-node/docker-compose.yml

cat <<EOL > ~/Marzban-node/docker-compose.yml
services:
  marzban-node:
    image: gozargah/marzban-node:latest
    restart: always
    network_mode: host
    environment:
      SSL_CERT_FILE: "/var/lib/marzban-node/ssl_cert.pem"
      SSL_KEY_FILE: "/var/lib/marzban-node/ssl_key.pem"
      SSL_CLIENT_CERT_FILE: "/var/lib/marzban-node/ssl_client_cert.pem"
      SERVICE_PROTOCOL: "rest"
    volumes:
      - /var/lib/marzban-node:/var/lib/marzban-node
EOL
curl -sSL https://raw.githubusercontent.com/Tozuck/Node_monitoring/main/node_monitor.sh | bash
rm /var/lib/marzban-node/ssl_client_cert.pem

cat <<EOL > /var/lib/marzban-node/ssl_client_cert.pem
-----BEGIN CERTIFICATE-----
MIIEnDCCAoQCAQAwDQYJKoZIhvcNAQENBQAwEzERMA8GA1UEAwwIR296YXJnYWgw
IBcNMjUwNTI4MTYyNDU0WhgPMjEyNTA1MDQxNjI0NTRaMBMxETAPBgNVBAMMCEdv
emFyZ2FoMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvDkcvo+XdT6i
gMzjAbqDY/w6f3BrXjn5+6ObCX3q1cH6X7PJ6aTWTcr3PbESkOxb5sER1ao3YLex
yX9iuZ1489SAdoQfYcmcZKSS1//sXXM7ZVdzvWPWa5RSfkgwCHUH0NLMoZZT8fkH
vZ7B4QAZ20ytKkwWixiY3fr01zCC71KhAMP0gOJWm/B3X96FtAiIw8OrcI3t66pl
PNcaEk1YgC/DbMB0p8LWfP+695J6B408MKb2J+OWTX/MZbgPNpmQdsVDN+piLZ0c
sAgjNcIR9FtM7PZnGZL+hmeFKhgWAE6hh7GpQ/0llUqKZtbeMBc2RYlv4gsBHoWF
0jLKbNZU4hDMujEmzcZ3kI0ohyql7TDTPCUngkmi/3Pjx6q0La3DRh66Oj0Pk/iW
/iEQLsJynFWl/cbVcIR7RmeC3Ea0rjV2hJ8QUpz1nJM7+pixMLuw/F7/QGavMT1h
wHqALqiXvrf4jILeLw4Yr7uIqxNfw+x2TCI8iDlkjvnkBEZ9Eej4p9p0Acmg/Bz6
Yw1lvcEJ5iQ39wyOGM1gpKlo3EFBBnpP/+nq9DgzT8BJnB5PqOSwlq4Fr+HYnmC0
TNy9FzxFXUAJEU7ewoTOZQO7ocy4SJWE94TKBGabOz/DJUMt598iQCtcj19vj8Ql
fJeCqmNX7XcXYo5UmtfLX4zDbSQDpUMCAwEAATANBgkqhkiG9w0BAQ0FAAOCAgEA
RxlvucdjzuaBBPsI1prgkpbh7byy7rnRvpckxEywvzK4QLt2ssqGS0Ntabu67BQS
QCiFFz2bJzpsNpCKgU++VRZG9evVsHYUqh59A3UBmnC9M7pN2qKXCJs+WIXeUxOq
uJMydwGTH4AQMVeecPQcCOtf+jUNT5VWfq98MzEH1uwOK5zaF+RO2c3qQpqfKjwK
gioGT6rXH0g2SIHfdPoa8RbXBFLyX2ubQ1Gh899DV+T9EjWbKvubvFDlnQt2aMJ8
mmNMTRVXoi30/LiObkSjsvoU0z9cU7M1gQ69O/ehl4s8q5O0FY0xSXeN3luWSWNh
SjT5HOUANbvPZWjU5uKnDzce/XRa+RJ8/6Z0Pjt/5epRFUazOWuEyknTrWMsnr/R
52ALyNv9BLuLYxzZqOUn9odCKqi9RZWUloVf3OqlT44RTMO1k8wtXoG+O+r8LaWH
ViLzVMWICS7RebVP73tyaXV1YmrXD8ugPHyXSvVoLofoKhbmsHF60QIQnX0r3HLu
kgwcSRuhbkQGZ3AaAFHc3vhZg3PSm+YLnuBSKxMIIbMm8Luj/cXOrWADUAvsP4pC
LMXxUYb12IeO8ZcTTqQmJhbZ0b7cqsd8rp8v3KNVyT6WWqzeezriXFi1lkZTfJgi
d1qwIM+wj7O7kRUzH4QxF8nkK40wzrbOM+97KuaWK0Y=
-----END CERTIFICATE-----
EOL

cd ~/Marzban-node
docker compose up -d

echo_info "Finalizing UFW setup..."

ufw allow 22
ufw allow 80
ufw allow 2096
ufw allow 2053
ufw allow 62050
ufw allow 62051

ufw --force enable
ufw reload
speedtest
