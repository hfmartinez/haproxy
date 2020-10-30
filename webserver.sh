
#archivo de aprovisionamiento webserver
echo "[Task 1] Update system"
apt-get update

echo "[Task 2] Add servers to /etc/hosts file"
echo '192.168.80.20 haproxyserver  haproxy' | tee -a /etc/hosts
echo '192.168.80.21 webserver1  web1' | tee -a /etc/hosts
echo '192.168.80.22 webserver2  web2' | tee -a /etc/hosts


echo "[Task 3] Install LXD cluster in webserver$1"
snap install lxd
gpasswd -a vagrant lxd
file=$(cat "/vagrant/cert.txt")

cat <<EOF | sudo lxd init --preseed
config: {}
networks: []
storage_pools: []
profiles: []
cluster:
  server_name: webserver$1
  enabled: true
  member_config:
  - entity: storage-pool
    name: local
    key: source
    value: ""
    description: '"source" property for storage pool "local"'
  cluster_address: 192.168.80.20:8443
  cluster_certificate: "$file"
  server_address: 192.168.80.2$1:8443
  cluster_password: haproxysecret
EOF

echo "[Task 4] Launch web$1 container"
lxc launch ubuntu:18.04 webserver$1 --target webserver$1 < /dev/null
sleep 5

echo "[Task 5] Update system and installation into web$1 container"
lxc exec webserver$1 -- apt-get update
lxc exec webserver$1 -- apt-get install apache2 -y

echo "[Task 6] apache2 setup"
cat <<index > /home/vagrant/index.html
<!DOCTYPE html>
<html>
<body>
<h1>Bienvenidos al servidor web$1</h1>
</body>
</html>
index

lxc file push /home/vagrant/index.html webserver$1/var/www/html/index.html

echo "[Task 7] Init apache2"
lxc exec webserver$1 -- service apache2 restart

if [ "$1" -eq "2" ]; then
  
  echo "[Task 8] Creating backup servers"
  lxc launch ubuntu:18.04 webserver3 --target webserver1 < /dev/null
  sleep 5
  lxc launch ubuntu:18.04 webserver4 --target webserver1 < /dev/null
  sleep 5
  lxc launch ubuntu:18.04 webserver5 --target webserver2 < /dev/null
  sleep 5
  lxc launch ubuntu:18.04 webserver6 --target webserver2 < /dev/null
  sleep 5
  echo "[Task 9] Update system and installation into backup servers"
  lxc exec webserver3 -- apt-get update
  lxc exec webserver3 -- apt-get install apache2 -y
  lxc exec webserver4 -- apt-get update
  lxc exec webserver4 -- apt-get install apache2 -y
  lxc exec webserver5 -- apt-get update
  lxc exec webserver5 -- apt-get install apache2 -y
  lxc exec webserver6 -- apt-get update
  lxc exec webserver6 -- apt-get install apache2 -y 
  echo "[Task 10] apache2 setup"
  cat <<index > /home/vagrant/index3.html
  <!DOCTYPE html>
  <html>
  <body>
  <h1>Bienvenidos al servidor web3</h1>
  </body>
  </html>  
index
  cat <<index > /home/vagrant/index4.html
  <!DOCTYPE html>
  <html>
  <body>
  <h1>Bienvenidos al servidor web4</h1>
  </body>
  </html>  
index
  cat <<index > /home/vagrant/index5.html
  <!DOCTYPE html>
  <html>
  <body>
  <h1>Bienvenidos al servidor web5</h1>
  </body>
  </html>  
index
  cat <<index > /home/vagrant/index6.html
  <!DOCTYPE html>
  <html>
  <body>
  <h1>Bienvenidos al servidor web6</h1>
  </body>
  </html>  
index
  lxc file push /home/vagrant/index3.html webserver3/var/www/html/index.html
  lxc file push /home/vagrant/index4.html webserver4/var/www/html/index.html
  lxc file push /home/vagrant/index5.html webserver5/var/www/html/index.html
  lxc file push /home/vagrant/index6.html webserver6/var/www/html/index.html
  lxc exec webserver3 -- service apache2 restart
  lxc exec webserver4 -- service apache2 restart
  lxc exec webserver5 -- service apache2 restart
  lxc exec webserver6 -- service apache2 restart

  echo "[Task 11] Haproxy service restart"
  lxc exec haproxy -- service haproxy restart

  echo "webserver$1 ok!"
else
  echo "webserver$1 ok!"
fi