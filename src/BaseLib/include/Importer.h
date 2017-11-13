//
// Created by Michael Heuer on 02.11.17.
//

#ifndef AMOLQCGUI_IMPORTER_H
#define AMOLQCGUI_IMPORTER_H

#include <fstream>
#include <tuple>
#include "AtomCollection.h"
#include "ElectronCollections.h"


class Importer{

public:
    explicit Importer(const std::string& filename);
    ~Importer();

    std::string getLine(unsigned long idx) const;

    template<typename Out>
    void split(const std::string &s, char delimiter, Out result) const;

    std::vector<std::string> split(const std::string &s) const;
    std::vector<std::string> split(const std::string &s, char delim) const;

    std::string strip(const std::string &s) const;
    std::string strip(const std::string &s, char delim) const;

private:
    template<class OutIt>
    void read_lines(std::istream& is, OutIt dest);

    std::string filename_;
    std::ifstream file_;
protected:
    std::vector<std::string> lines_;
};

class SubstructureDataEntry{
public:
    SubstructureDataEntry(unsigned long startingLine,
                          unsigned long numberOfSubstructures,
                          unsigned long totalNumberOfMaxima = 1)
            : startingLine_(startingLine),
              numberOfSubstructures_(numberOfSubstructures),
              totalNumberOfMaxima_(totalNumberOfMaxima) {};

    unsigned long startingLine_, numberOfSubstructures_, totalNumberOfMaxima_;
};

#endif //AMOLQCGUI_IMPORTER_H
