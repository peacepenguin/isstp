#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char* argv[])
{
    char buf[512];
    char pppd_args[512] = {0};
 
    setuid(0);
    if (!strcmp(argv[1], "start") && argc > 6) {
        for (int i = 6; i < argc; ++i) {
            sprintf(pppd_args, "%s %s", pppd_args, argv[i]);
        }
        sprintf(buf, "%s --user %s --password %s %s %s",
                argv[2], argv[3], argv[4], argv[5], pppd_args);
        system(buf);
    } else if (!strcmp(argv[1], "stop")) {
        system("killall sstpc helper");
    } else if (!strcmp(argv[1], "route") && argc > 2) {
        sprintf(buf, "route add -net %s -interface ppp0", argv[2]);
        system(buf);
    } else {
        return -1;
    }
}
