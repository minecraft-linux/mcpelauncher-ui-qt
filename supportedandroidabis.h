#pragma once
#include <map>
#include <string>

struct AndroidAbiComparer {
    bool operator()(const std::string& a, const std::string& b) const;
    std::size_t operator()(const std::string& a) const;
};

class SupportedAndroidAbis {
public:
    static std::map<std::string, std::string, AndroidAbiComparer> getAbis();
};