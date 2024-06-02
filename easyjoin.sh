#!/bin/bash
###автор Казанцев Михаил Валеьевич (kazan417@mail.ru) лицензия MIT
echo "скрипт ввода компьютера в домен"
if [ -n "$(command -v yum)" ]; then
  if [[ $EUID -ne 0 ]]; then
     echo "введите пароль суперпользователя"
     su -c 	"/bin/bash ./easyjoin.sh"
     exit 0
  fi
  if [[ $EUID -ne 0 ]]; then
  echo "ошибка получения прав суперпользователя"
  exit 1
  fi
export PATH=$PATH:/usr/sbin
echo "введите новое имя компьютера например: adm-k12-1-redos"
read pcname
echo "введите имя пользователя домена"
read domainuser
echo "введите домен вида DOMAIN.LOCAL"
read domain
echo "найден yum устанавливаем требуемые программы с помощью yum"
yum update -y
echo "Установка программ для ввода в домен"
yum install -y realmd sssd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation
sed -i '/\[libdefaults\]/a \
   allow_weak_crypto = true\
   default_tgs_enctypes = aes256-cts-hmac-sha1-96 rc4-hmac des-cbc-crc des-cbc-md5\
   default_tkt_enctypes = aes256-cts-hmac-sha1-96 rc4-hmac des-cbc-crc des-cbc-md5\
   permitted_enctypes = aes256-cts-hmac-sha1-96 rc4-hmac des-cbc-crc des-cbc-md5\
   supported_enctypes = aes256-cts:normal aes128-cts:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des3-hmac-sha1:normal' /etc/krb5.conf
sed -i 's;default_ccache_name = KEYRING:persistent:%{uid};default_ccache_name = FILE:/tmp/krb5cc_%{uid};g' /etc/krb5.conf
sed -i "/krb5cc_%{uid}/a default_realm = $domain" /etc/krb5.conf
echo "настройка синхронизации времени с сервером времени"
echo "server $domain iburst" >> /etc/chrony.conf
timedatectl set-timezone Asia/Novokuznetsk
systemctl restart chronyd
chronyc tracking
hostnamectl set-hostname $pcname.$domain
hostname
echo '127.0.0.1  `hostname -f` `hostname -s`' >> /etc/hosts
systemctl restart NetworkManager
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
echo 'ad_gpo_access_control = permissive' >> /etc/sssd/sssd.conf
authconfig --enablemkhomedir --enablesssdauth --updateall
echo '*               -       nofile          16384' >> /etc/security/limits.conf
echo 'root            -       nofile          16384' >> /etc/security/limits.conf
echo '%администраторы\ домена ALL=(ALL) ALL' >> /etc/sudoers
echo '%domain\ admins ALL=(ALL) ALL' >> /etc/sudoers
realm join -U -v $domainuser $domain
fi

if [ -n "$(command -v apt-get)" ]; then
	echo "найден apt-get устанавливаем требуемые программы с помощью apt-get"
  if [[ $EUID -ne 0 ]]; then
     echo "введите пароль суперпользователя"
     su -c 	"/bin/bash ./easyjoin.sh"
     exit 0
  fi
  if [[ $EUID -ne 0 ]]; then
  echo "ошибка получения прав суперпользователя"
  exit 1
  fi
echo "введите новое имя компьютера например: adm-k12-1-redos"
read pcname
echo "введите имя пользователя домена"
read domainuser
echo "введите домен вида DOMAIN.LOCAL"
read domain
echo "введите имя контроллера домена вида dc.domain.loal"
read domaincontroller
apt-get -y install chrony astra-ad-sssd-client
echo "настройка синхронизации времени с сервером времени"
echo 'server $domain iburst' >> /etc/chrony/chrony.conf
timedatectl set-timezone Asia/Novokuznetsk
systemctl restart chronyd
chronyc tracking
hostnamectl set-hostname $pcname.$domain
hostname
echo '127.0.0.1  `hostname -f` `hostname -s`' >> /etc/hosts
systemctl restart NetworkManager
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
##echo 'ad_gpo_access_control = permissive' >> /etc/sssd/sssd.conf
##authconfig --enablemkhomedir --enablesssdauth --updateall
echo '*               -       nofile          16384' >> /etc/security/limits.conf
echo 'root            -       nofile          16384' >> /etc/security/limits.conf
echo '%администраторы\ домена ALL=(ALL) ALL' >> /etc/sudoers
echo '%domain\ admins ALL=(ALL) ALL' >> /etc/sudoers
astra-ad-sssd-client -d $domain -u $domainuser -dc $domaincontroller
fi
echo "компьютер успешно введен в домен. Нажмите любую клавишу..."
read




