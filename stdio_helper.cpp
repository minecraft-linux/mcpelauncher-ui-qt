#include "stdio_helper.h"

void StdioHelper::write(const QString &msg) {
    // Write raw text to stdout, no timestamps, no log categories
    std::cout << msg.toStdString() << std::endl;
}

void StdioHelper::error(const QString &msg) {
    // Write raw text to stderr, no timestamps, no log categories
    std::cerr << msg.toStdString() << std::endl;
}
