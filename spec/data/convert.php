<?
require('wordpress_autop.php');
$dp = opendir("./in");
while (false !== ($entry = readdir($dp))) {
  $data = file_get_contents("in/" . $entry);
  $out = wpautop($data, 0);
  $fp = fopen("out/" . $entry, "w");
  fwrite($fp, $out);
  fclose($fp);
}
fclose($dp);