package Apache::Ocsinventory::Plugins::Softwareactivity::Map;
 
use strict;
 
use Apache::Ocsinventory::Map;
$DATA_MAP{softwareactivity} = {
   mask => 0,
   multi => 1,
   auto => 1,
   delOnReplace => 1,
   sortBy => 'ID',
   writeDiff => 0,
   cache => 0,
   fields => {
      ACCESSED_AT => {},
      APP_NAME => {},
      AVERAGE_USAGE => {}
   }
};
1;