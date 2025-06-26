<?php
function extension_install_activitywatchwindows()
{
    $commonObject = new ExtensionCommon;

    $commonObject -> sqlQuery(
        "CREATE TABLE example (
        ID INTEGER NOT NULL AUTO_INCREMENT, 
        HARDWARE_ID INTEGER NOT NULL,
        ACCESSED_AT DATETIME NOT NULL,
        APP_NAME VARCHAR(255) DEFAULT NULL,
        PRIMARY KEY (ID,HARDWARE_ID)) ENGINE=INNODB;"
    );
}

function extension_delete_activitywatchwindows()
{
    $commonObject = new ExtensionCommon;
    $commonObject -> sqlQuery("DROP TABLE IF EXISTS `example`");
}

function extension_upgrade_activitywatchwindows()
{

}

?>