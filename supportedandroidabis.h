#pragma once
#include <map>
#include <string>

struct AndroidAbiComparer {
    bool operator()(const std::string& a, const std::string& b) const;
    std::size_t operator()(const std::string& a) const;
};

struct SupportReport
{
    bool compatible;
    std::string launchername;
    std::string details;
};

bool Supports32Bit();
bool ProcessIsTranslated();

class SupportedAndroidAbis {
public:
    static std::map<std::string, SupportReport, AndroidAbiComparer> getAbis();
};