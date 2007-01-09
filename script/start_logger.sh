#echo 'require "./script/logreader.rb"' | ./script/console

nohup ./script/logreader.rb /var/log/apache2/stats.crumbtrail/access.log &