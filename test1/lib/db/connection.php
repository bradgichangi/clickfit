<?php
try{
$connection = new PDO('mysql:host=localhost,dbname=clickfit','root','');
$connection ->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);
echo "Connected";
}
catch(PDOException $exc){
	echo $exc ->getMassage();
	die("Couldn't connect")
}
?>