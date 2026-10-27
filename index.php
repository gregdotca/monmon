<?php
header("Expires: Tue, 01 Jan 2000 00:00:00 GMT");
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header("refresh: 10; url = " . $_SERVER['PHP_SELF']);

$are_there_issues = 0;

// check.py leaves this file after each run. /run is emptied at every boot, so it's only
// missing until the first check.py run after a boot
$has_checked = file_exists('/run/monmon-checked');

if ($has_checked && file_exists('alerts')) {

    $are_there_issues = 1;
    $background_colour = '#FFFFFF';

} else {

    $background_colour = '#000000';

}
?>
<html>
<head>
    <title>monmon</title>
    <style>
        html {
            font-family: Verdana, Geneva, sans-serif;
            font-size: 20px;
            text-align: center;
        }
        body {
            line-height: 28px;
            padding-top: 50px;
            background-color: <?php echo $background_colour; ?>;
        }
        a {
            line-height: 1.65em;
            text-decoration: none;
        }
        .blinking{
            animation:blinkingText 1.2s infinite;
        }
        @keyframes blinkingText{
            0%{     color: red;    }
            49%{    color: red; }
            60%{    color: transparent; }
            99%{    color: transparent;  }
            100%{   color: red;    }
        }
    </style>
</head>
<body>
<?php
if (!$has_checked) {

    echo '<span style="color: grey;">Starting...</span>';

} elseif ($are_there_issues === 0) {

    echo '<span style="color: green;">ALL SYSTEMS GO!<span>';

}  else {

    include('alerts');

} ?>
</body>
</html>
