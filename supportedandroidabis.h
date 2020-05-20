#pragma once
#include <vector>
#include <string>

class SupportedAndroidAbis {
public:
    static std::vector<std::string> getSupportedAbis();
    static std::vector<std::string> getAbis();
};