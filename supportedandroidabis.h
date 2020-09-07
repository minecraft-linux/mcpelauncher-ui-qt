#pragma once
#include <unordered_map>
#include <string>

class SupportedAndroidAbis {
public:
    static std::unordered_map<std::string, std::string> getAbis();
};