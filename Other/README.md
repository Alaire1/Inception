# Evalaution comnmands:
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
## Simple stetup:
1. accessing only port 443 on nginx
- username.42.fr:80 (http)
- nc -sv username.42.fr 80
- sudo iptables -a INPUT -n -v
2. SSL/TLS certificate proof
- openssl s_clinet -connect username.42.fr:443 -tls1_1
-
