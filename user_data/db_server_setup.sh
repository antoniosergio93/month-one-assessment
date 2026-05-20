#!/bin/bash -xe

sudo yum update -y

sudo yum install -y postgresql-server postgresql

sudo postgresql-setup initdb

sudo systemctl enable postgresql
sudo systemctl start postgresql

# Listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" \
/var/lib/pgsql/data/postgresql.conf

# Allow connections from VPC network
echo "host all all 10.0.0.0/16 md5" | sudo tee -a \
/var/lib/pgsql/data/pg_hba.conf

sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'AltschoolPassword123';"

sudo systemctl restart postgresql

sudo systemctl status postgresql --no-pager