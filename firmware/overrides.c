#include "diskimg.h"

const char *bootvhd_name="TSConf  vhd";

char *autoboot()
{
        char *result=0;
        diskimg_mount(bootvhd_name,0);
        return(result);
}

