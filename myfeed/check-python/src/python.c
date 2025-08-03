#include <stdio.h>
#include <stdlib.h>

int main() {
    if (system("which python3.9 > /dev/null 2>&1") != 0) {
        printf("Error: Python 3.9 not found\n");
        return 1;
    }

    FILE *fp = popen("python3.9 --version", "r");
    if (fp == NULL) {
        printf("Error: Failed to run command\n");
        return 1;
    }

    char buffer[128];
    if (fgets(buffer, sizeof(buffer), fp) != NULL) {
        printf("Detected Python Version: %s", buffer);
        FILE *log = fopen("/tmp/python_ver.log", "w");
        if (log != NULL) {
            fprintf(log, "%s", buffer);
            fclose(log);
        }
    }
    pclose(fp);
    return 0;
}
