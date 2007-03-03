./script/create_test_data.rb
mysql achilles_development < ./script/db/achilles_production-accountsprojects 2> /dev/null
./script/logreader.rb $1
