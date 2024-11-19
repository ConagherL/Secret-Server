$params = $args
$server = $params[0]
$port = $params[1]
$user = $params[2]
$password = $params[3]
$newPassword = $params[4]

# Install: pip install cassandra-driver
$pyCode = "import cassandra
import sys
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider

server = [str(sys.argv[1])]
port = int(sys.argv[2])
user = str(sys.argv[3])
pwd = str(sys.argv[4])
newPwd = str(sys.argv[5])
auth = PlainTextAuthProvider(user,pwd)
cluster = Cluster(server, port = port, auth_provider=auth)
session = cluster.connect()

cmd = 'ALTER USER ' + user + ' WITH PASSWORD \'' + newPwd + '\''

try:
    session.execute(cmd)
except:
    raise TypeError('Error changing password')
finally:
    cluster.shutdown
    print('Successful')"

& 'C:\Program Files (x86)\Python38-32\python.exe' -c $pyCode $server $port $user $password $newPassword